const statusValue = document.getElementById("statusValue");
const messageBox = document.getElementById("message");
const dockerButton = document.getElementById("dockerButton");
const vboxButton = document.getElementById("vboxButton");

const setBusy = (busy) => {
  dockerButton.disabled = busy;
  vboxButton.disabled = busy;
};

const showMessage = (text, type) => {
  if (!text) {
    messageBox.className = "message hidden";
    messageBox.textContent = "";
    return;
  }

  messageBox.textContent = text;
  messageBox.className = `message ${type}`;
};

const fetchStatus = async () => {
  try {
    const response = await fetch("/status");
    const data = await response.json();
    statusValue.textContent = data.status || "Status unbekannt";
  } catch (error) {
    statusValue.textContent = "Status unbekannt";
  }
};

const runAction = async (type, label) => {
  setBusy(true);
  showMessage(`${label} wird gestartet...`, "info");

  try {
    const response = await fetch(`/launch/${type}`, {
      method: "POST",
    });
    const data = await response.json();

    if (!response.ok || !data.success) {
      showMessage(data.error || "Befehl fehlgeschlagen.", "error");
    } else {
      showMessage(`${label} gestartet.`, "success");
    }

    statusValue.textContent = data.status || "Status unbekannt";
  } catch (error) {
    showMessage("Netzwerkfehler: Anfrage fehlgeschlagen.", "error");
  } finally {
    setBusy(false);
  }
};

dockerButton.addEventListener("click", () => {
  runAction("docker", "Docker Desktop");
});

vboxButton.addEventListener("click", () => {
  runAction("virtualbox", "VirtualBox");
});

fetchStatus();
setInterval(fetchStatus, 10000);
