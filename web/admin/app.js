import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  limit,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  updateDoc,
} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js";
import {
  getDownloadURL,
  getStorage,
  deleteObject,
  ref,
  uploadBytes,
} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-storage.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyC33Lr1pdGaSkYSJ3lloKpIlhtmzrMO-iA",
  appId: "1:607840749804:web:4963b08a4fe7f4c9157dc9",
  messagingSenderId: "607840749804",
  projectId: "eventos-app-f3141",
  authDomain: "eventos-app-f3141.firebaseapp.com",
  storageBucket: "eventos-app-f3141.firebasestorage.app",
  measurementId: "G-2N7314XR2B",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const storage = getStorage(app);

const $ = (id) => document.getElementById(id);

const state = {
  events: [],
  unsubscribeEvents: null,
};

function showToast(message) {
  const toast = $("toast");
  toast.textContent = message;
  toast.classList.add("show");
  window.setTimeout(() => toast.classList.remove("show"), 3600);
}

function setLoading(button, isLoading, label) {
  button.disabled = isLoading;
  button.textContent = isLoading ? "Aguarde..." : label;
}

function toDateInputValue(date) {
  const offset = date.getTimezoneOffset();
  const local = new Date(date.getTime() - offset * 60000);
  return local.toISOString().slice(0, 16);
}

function fromDatetimeLocal(value) {
  return value ? Timestamp.fromDate(new Date(value)) : null;
}

function parseFirebaseDate(value) {
  if (value?.toDate) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  return null;
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function isEventFromToday(event) {
  const date = parseFirebaseDate(event.dataEvento);
  if (!date) return false;
  return startOfDay(date) >= startOfDay(new Date());
}

function formatEventDate(value) {
  const date = parseFirebaseDate(value);
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) return "-";
  return new Intl.DateTimeFormat("pt-BR", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

function eventImage(data) {
  const urls = data.imagemUrls;
  if (Array.isArray(urls) && urls.length > 0) return urls[0];
  if (typeof urls === "string") return urls;
  return "";
}

function storageRefFromDownloadUrl(url) {
  if (!url) return null;
  try {
    return ref(storage, url);
  } catch (error) {
    console.warn("Nao foi possivel criar referencia da imagem.", error);
    return null;
  }
}

function eventOptionLabel(event) {
  return `${event.titulo || "Sem titulo"} - ${formatEventDate(event.dataEvento)}`;
}

function renderEvents() {
  const list = $("eventsList");
  const select = $("pushEventId");
  const futureCount = state.events.filter(isEventFromToday).length;

  $("futureCount").textContent = String(futureCount);
  $("lastEventDate").textContent = state.events[0]
    ? formatEventDate(state.events[0].criadoEm || state.events[0].dataEvento)
    : "-";

  select.innerHTML = '<option value="">Sem evento especifico</option>';
  for (const event of state.events) {
    const option = document.createElement("option");
    option.value = event.id;
    option.textContent = eventOptionLabel(event);
    select.appendChild(option);
  }

  if (state.events.length === 0) {
    list.innerHTML = '<p class="text-slate-500">Nenhum evento encontrado.</p>';
    return;
  }

  list.innerHTML = "";
  for (const event of state.events) {
    const item = document.createElement("article");
    item.className = "event-item";

    const imageUrl = eventImage(event);
    const image = document.createElement(imageUrl ? "img" : "div");
    image.className = "event-thumb";
    if (imageUrl) {
      image.src = imageUrl;
      image.alt = "";
    }

    const content = document.createElement("div");
    content.className = "event-content";
    content.innerHTML = `
      <div>
        <h4>${event.titulo || "Sem titulo"}</h4>
        <p>${event.cidade || "Cidade nao informada"}</p>
        <p>${formatEventDate(event.dataEvento)}</p>
      </div>
      <button
        class="danger-button"
        type="button"
        data-delete-event="${event.id}"
        aria-label="Excluir evento ${event.titulo || "sem titulo"}"
        title="Excluir evento"
      >
        <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
          <path d="M3 6h18" />
          <path d="M8 6V4h8v2" />
          <path d="M19 6l-1 14H6L5 6" />
          <path d="M10 11v5" />
          <path d="M14 11v5" />
        </svg>
      </button>
    `;

    item.append(image, content);
    list.appendChild(item);
  }
}

async function deleteEvent(eventId) {
  const event = state.events.find((item) => item.id === eventId);
  if (!event) return;

  const confirmed = window.confirm(
    `Excluir o evento "${event.titulo || "Sem titulo"}"?`,
  );
  if (!confirmed) return;

  try {
    const imageRefs = [];
    const urls = event.imagemUrls;
    if (Array.isArray(urls)) {
      for (const url of urls) {
        const imageRef = storageRefFromDownloadUrl(url);
        if (imageRef) imageRefs.push(imageRef);
      }
    } else if (typeof urls === "string") {
      const imageRef = storageRefFromDownloadUrl(urls);
      if (imageRef) imageRefs.push(imageRef);
    }

    await Promise.allSettled(imageRefs.map((imageRef) => deleteObject(imageRef)));
    await deleteDoc(doc(db, "eventos", eventId));
    showToast("Evento excluido.");
  } catch (error) {
    console.error(error);
    showToast(error.message || "Nao foi possivel excluir o evento.");
  }
}

function eventsQuery() {
  return query(
    collection(db, "eventos"),
    orderBy("dataEvento", "desc"),
    limit(24),
  );
}

function applyEventsSnapshot(snapshot) {
  state.events = snapshot.docs.map((docSnapshot) => ({
    id: docSnapshot.id,
    ...docSnapshot.data(),
  }));
  renderEvents();
  $("firebaseStatus").textContent = "Online";
}

function watchEvents() {
  $("firebaseStatus").textContent = "Carregando eventos";

  if (state.unsubscribeEvents) {
    state.unsubscribeEvents();
  }

  state.unsubscribeEvents = onSnapshot(
    eventsQuery(),
    applyEventsSnapshot,
    (error) => {
      console.error(error);
      $("firebaseStatus").textContent = "Erro";
      showToast("Nao foi possivel acompanhar os eventos em tempo real.");
    },
  );
}

async function uploadEventImage(file, eventId) {
  if (!file) return "";
  const extension = file.name.split(".").pop() || "jpg";
  const safeName = `${Date.now()}.${extension.toLowerCase()}`;
  const imageRef = ref(storage, `eventos/${eventId}/${safeName}`);
  await uploadBytes(imageRef, file, { contentType: file.type || "image/jpeg" });
  return getDownloadURL(imageRef);
}

async function createPushRequest({ title, body, eventId = "", type = "manual" }) {
  const payload = {
    title,
    body,
    topic: "eventos",
    status: "pending",
    type,
    route: eventId ? "/detalhes_evento" : "/",
    eventId,
    createdAt: serverTimestamp(),
  };

  await addDoc(collection(db, "push_requests"), payload);
  $("lastPushStatus").textContent = "Criado";
}

async function handleEventSubmit(event) {
  event.preventDefault();
  const button = $("saveEventButton");
  setLoading(button, true, "Salvar evento");

  try {
    const titulo = $("titulo").value.trim();
    const cidade = $("cidade").value.trim();
    const descricao = $("descricao").value.trim();
    const dataEvento = fromDatetimeLocal($("dataEvento").value);
    const dataFimEvento = fromDatetimeLocal($("dataFimEvento").value);
    const file = $("imagem").files[0];

    if (!titulo || !cidade || !dataEvento) {
      throw new Error("Preencha titulo, cidade e data de inicio.");
    }

    const docRef = await addDoc(collection(db, "eventos"), {
      titulo,
      cidade,
      descricao,
      dataEvento,
      dataFimEvento,
      imagemUrls: [],
      curtidas: 0,
      criadoEm: serverTimestamp(),
    });

    const imageUrl = await uploadEventImage(file, docRef.id);
    if (imageUrl) {
      await updateDoc(doc(db, "eventos", docRef.id), {
        imagemUrls: [imageUrl],
      });
    }

    if ($("sendPushAfterCreate").checked) {
      const title = $("eventPushTitle").value.trim() || titulo;
      const body =
        $("eventPushBody").value.trim() ||
        `${cidade} recebeu um novo evento no app.`;
      await createPushRequest({
        title,
        body,
        eventId: docRef.id,
        type: "event_created",
      });
    }

    event.target.reset();
    $("dataEvento").value = toDateInputValue(new Date());
    $("eventPushFields").classList.add("hidden");
    showToast("Evento cadastrado com sucesso.");
  } catch (error) {
    console.error(error);
    showToast(error.message || "Nao foi possivel salvar o evento.");
  } finally {
    setLoading(button, false, "Salvar evento");
  }
}

async function handlePushSubmit(event) {
  event.preventDefault();
  const button = $("sendPushButton");
  setLoading(button, true, "Criar envio");

  try {
    await createPushRequest({
      title: $("pushTitle").value.trim(),
      body: $("pushBody").value.trim(),
      eventId: $("pushEventId").value,
    });
    event.target.reset();
    showToast("Solicitacao de push criada.");
  } catch (error) {
    console.error(error);
    showToast(error.message || "Nao foi possivel criar o push.");
  } finally {
    setLoading(button, false, "Criar envio");
  }
}

function bindUi() {
  $("eventForm").addEventListener("submit", handleEventSubmit);
  $("pushForm").addEventListener("submit", handlePushSubmit);
  $("refreshEvents").addEventListener("click", async () => {
    watchEvents();
    showToast("Sincronizacao em tempo real reiniciada.");
  });
  $("sendPushAfterCreate").addEventListener("change", (event) => {
    $("eventPushFields").classList.toggle("hidden", !event.target.checked);
  });
  $("eventsList").addEventListener("click", async (event) => {
    const button = event.target.closest("[data-delete-event]");
    if (!button) return;
    await deleteEvent(button.dataset.deleteEvent);
  });
}

async function boot() {
  bindUi();
  $("dataEvento").value = toDateInputValue(new Date());

  try {
    watchEvents();
  } catch (error) {
    console.error(error);
    $("firebaseStatus").textContent = "Erro";
    showToast("Confira as regras e a conexao com o Firebase.");
  }
}

boot();
