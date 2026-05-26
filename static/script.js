const statusEl = document.getElementById("status");
const messageEl = document.getElementById("message");
const errorEl = document.getElementById("error");
const dockerBtn = document.getElementById("dockerBtn");
const vboxBtn = document.getElementById("vboxBtn");

function setBusy(isBusy) {
  dockerBtn.disabled = isBusy;
  vboxBtn.disabled = isBusy;
}

function setStatus(text) {
  statusEl.textContent = `Status: ${text}`;
}

async function loadStatus() {
  try {
    const response = await fetch("/api/status");
    const data = await response.json();
    setStatus(data.status || "Unbekannt");
  } catch {
    setStatus("Unbekannt");
  }
}

async function runAction(endpoint) {
  setBusy(true);
  messageEl.textContent = "Bitte warten ...";
  errorEl.textContent = "";

  try {
    const response = await fetch(endpoint, { method: "POST" });
    const data = await response.json();
    setStatus(data.status || "Unbekannt");

    if (!response.ok || !data.ok) {
      messageEl.textContent = data.message || "Fehler beim Ausführen.";
      errorEl.textContent = data.details || "";
      return;
    }

    messageEl.textContent = data.message || "Erfolgreich.";
  } catch {
    messageEl.textContent = "Netzwerkfehler beim Aufruf des Backends.";
  } finally {
    setBusy(false);
  }
}

dockerBtn.addEventListener("click", () => runAction("/api/start/docker"));
vboxBtn.addEventListener("click", () => runAction("/api/start/virtualbox"));

loadStatus();
