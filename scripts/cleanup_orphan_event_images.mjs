#!/usr/bin/env node

import { execFileSync } from 'node:child_process';

const projectId = 'eventos-app-f3141';
const bucket = 'eventos-app-f3141.firebasestorage.app';
const collectionPath = 'eventos';
const storagePrefix = 'eventos/';

const args = new Set(process.argv.slice(2));
const shouldDelete = args.has('--delete');
const assumeYes = args.has('--yes');

if (shouldDelete && !assumeYes) {
  console.error('Use --delete --yes para confirmar a exclusao real.');
  process.exit(2);
}

const token = getAccessToken();

const firestoreDocs = await listFirestoreDocuments();
const referencedObjects = new Set();
const referencedUrls = new Set();

for (const doc of firestoreDocs) {
  for (const url of imageUrlsFromFirestoreFields(doc.fields ?? {})) {
    referencedUrls.add(url);
    const objectName = objectNameFromStorageUrl(url);
    if (objectName != null) {
      referencedObjects.add(objectName);
    }
  }
}

const storageObjects = await listStorageObjects();
const orphanObjects = storageObjects
  .filter((object) => object.name !== storagePrefix)
  .filter((object) => !object.name.endsWith('/'))
  .filter((object) => !referencedObjects.has(object.name));

printSummary({
  firestoreDocsCount: firestoreDocs.length,
  referencedUrlsCount: referencedUrls.size,
  referencedObjectsCount: referencedObjects.size,
  storageObjectsCount: storageObjects.length,
  orphanObjects,
});

if (!shouldDelete) {
  console.log('\nDry-run apenas. Rode com --delete --yes para apagar.');
  process.exit(0);
}

for (const object of orphanObjects) {
  await deleteStorageObject(object.name);
  console.log(`apagado: ${object.name}`);
}

console.log(`\nLimpeza concluida. Objetos apagados: ${orphanObjects.length}`);

function getAccessToken() {
  if (process.env.FIREBASE_TOKEN?.trim()) {
    return process.env.FIREBASE_TOKEN.trim();
  }

  const output = execFileSync('firebase', ['login:list', '--json'], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  const parsed = JSON.parse(output);
  const accessToken = parsed.result?.[0]?.tokens?.access_token;
  if (typeof accessToken !== 'string' || accessToken.trim() === '') {
    throw new Error('Sessao do Firebase CLI nao encontrada.');
  }

  return accessToken;
}

async function listFirestoreDocuments() {
  const docs = [];
  let pageToken = '';

  do {
    const params = new URLSearchParams({ pageSize: '300' });
    if (pageToken !== '') {
      params.set('pageToken', pageToken);
    }

    const response = await authedFetch(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${collectionPath}?${params}`,
    );
    docs.push(...(response.documents ?? []));
    pageToken = response.nextPageToken ?? '';
  } while (pageToken !== '');

  return docs;
}

async function listStorageObjects() {
  const objects = [];
  let pageToken = '';

  do {
    const params = new URLSearchParams({
      prefix: storagePrefix,
      maxResults: '1000',
    });
    if (pageToken !== '') {
      params.set('pageToken', pageToken);
    }

    const response = await authedFetch(
      `https://storage.googleapis.com/storage/v1/b/${encodeURIComponent(bucket)}/o?${params}`,
    );
    objects.push(...(response.items ?? []));
    pageToken = response.nextPageToken ?? '';
  } while (pageToken !== '');

  return objects;
}

async function deleteStorageObject(objectName) {
  await authedFetch(
    `https://storage.googleapis.com/storage/v1/b/${encodeURIComponent(bucket)}/o/${encodeURIComponent(objectName)}`,
    { method: 'DELETE', expectJson: false },
  );
}

async function authedFetch(url, { method = 'GET', expectJson = true } = {}) {
  const response = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`${method} ${url} falhou (${response.status}): ${body}`);
  }

  if (!expectJson || response.status === 204) {
    return null;
  }

  return response.json();
}

function imageUrlsFromFirestoreFields(fields) {
  const urls = new Set();
  addFirestoreFieldValue(urls, fields.imagemUrls);
  addFirestoreFieldValue(urls, fields.imagemUrl);
  addFirestoreFieldValue(urls, fields.imageUrl);
  return urls;
}

function addFirestoreFieldValue(urls, field) {
  if (field == null) {
    return;
  }

  if (typeof field.stringValue === 'string') {
    const url = field.stringValue.trim();
    if (url !== '') {
      urls.add(url);
    }
  }

  for (const value of field.arrayValue?.values ?? []) {
    addFirestoreFieldValue(urls, value);
  }
}

function objectNameFromStorageUrl(rawUrl) {
  const url = rawUrl.trim();
  if (url === '') {
    return null;
  }

  if (url.startsWith(`gs://${bucket}/`)) {
    return url.slice(`gs://${bucket}/`.length);
  }

  try {
    const parsed = new URL(url);

    if (
      parsed.hostname === 'firebasestorage.googleapis.com' &&
      parsed.pathname.startsWith(`/v0/b/${bucket}/o/`)
    ) {
      const encodedObjectName = parsed.pathname.slice(
        `/v0/b/${bucket}/o/`.length,
      );
      return decodeURIComponent(encodedObjectName);
    }

    if (
      parsed.hostname === 'storage.googleapis.com' &&
      parsed.pathname.startsWith(`/${bucket}/`)
    ) {
      return decodeURIComponent(parsed.pathname.slice(`/${bucket}/`.length));
    }

    if (parsed.hostname === `${bucket}.storage.googleapis.com`) {
      return decodeURIComponent(parsed.pathname.replace(/^\/+/, ''));
    }
  } catch (_) {
    return null;
  }

  return null;
}

function printSummary({
  firestoreDocsCount,
  referencedUrlsCount,
  referencedObjectsCount,
  storageObjectsCount,
  orphanObjects,
}) {
  console.log(`Projeto: ${projectId}`);
  console.log(`Bucket: gs://${bucket}/${storagePrefix}`);
  console.log(`Eventos no Firestore: ${firestoreDocsCount}`);
  console.log(`URLs de imagem referenciadas: ${referencedUrlsCount}`);
  console.log(`Objetos referenciados no bucket: ${referencedObjectsCount}`);
  console.log(`Objetos no Storage sob ${storagePrefix}: ${storageObjectsCount}`);
  console.log(`Objetos orfaos encontrados: ${orphanObjects.length}`);

  if (orphanObjects.length === 0) {
    return;
  }

  console.log('\nCandidatos a exclusao:');
  for (const object of orphanObjects) {
    const size = Number.parseInt(object.size ?? '0', 10);
    const sizeLabel = Number.isFinite(size) ? `${size} bytes` : 'tamanho ?';
    console.log(`- ${object.name} (${sizeLabel})`);
  }
}
