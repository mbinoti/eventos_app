const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const DEFAULT_TOPIC = "eventos";

function asDataPayload(data) {
  const payload = {
    route: data.route || "/",
    type: data.type || "manual",
  };

  if (data.eventId) {
    payload.id = String(data.eventId);
    payload.eventId = String(data.eventId);
  }

  return payload;
}

exports.sendPushRequest = onDocumentCreated(
  "push_requests/{requestId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const requestRef = getFirestore().doc(snapshot.ref.path);
    const title = String(data.title || "").trim();
    const body = String(data.body || "").trim();
    const topic = String(data.topic || DEFAULT_TOPIC).trim();

    if (!title || !body) {
      await requestRef.update({
        status: "failed",
        error: "Titulo e mensagem sao obrigatorios.",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    try {
      const messageId = await getMessaging().send({
        topic,
        notification: { title, body },
        data: asDataPayload(data),
        android: {
          priority: "high",
          notification: {
            channelId: "eventos_app_channel",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      await requestRef.update({
        status: "sent",
        messageId,
        processedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      await requestRef.update({
        status: "failed",
        error: error.message || String(error),
        processedAt: FieldValue.serverTimestamp(),
      });
      throw error;
    }
  },
);
