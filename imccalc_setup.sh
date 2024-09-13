#!/bin/bash

mkdir -p imccalc/{_locales/pt_BR,_locales/en,_locales/es}

cat > imccalc/manifest.json <<EOL
{
  "manifest_version": 3,
  "name": "IMCCalc",
  "version": "2.1",
  "description": "Calculadora de IMC com persistência no IndexedDB e exportação para CSV.",
  "default_locale": "pt_BR",
  "action": {
    "default_popup": "popup.html",
    "default_icon": "icon.png"
  },
  "permissions": ["storage", "notifications"],
  "icons": {
    "48": "icon.png",
    "128": "icon.png"
  }
}
EOL

cat > imccalc/popup.html <<EOL
<!DOCTYPE html>
<html lang="pt">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="styles.css">
  <title>IMCCalc</title>
</head>
<body>
  <div id="container">
    <h1 id="app-name"></h1>

    <h2 id="bmi-header"></h2>
    <div id="bmi-calculator">
      <label for="bmi-weight" id="weight-label"></label>
      <input type="number" id="bmi-weight" placeholder="">
      <label for="bmi-height" id="height-label"></label>
      <input type="number" id="bmi-height" placeholder="">
      <button id="calculate-bmi"></button>
      <p id="bmi-result"></p>

      <div id="bmi-classification" class="classification-box" style="display: none;"></div>
    </div>

    <div id="theme-toggle" style="margin-top: 15px;">
      <label for="theme-dropdown">Escolha o tema:</label>
      <select id="theme-dropdown">
        <option value="light">Tema Claro</option>
        <option value="dark">Tema Escuro</option>
      </select>
    </div>

    <p id="settings-text" style="cursor: pointer;"></p>

    <div id="modal-overlay"></div>
    <div id="settings-modal">
      <button class="modal-button" id="export-csv">Exportar para CSV</button>
      <button class="modal-button" id="delete-db">Apagar Informações</button>
    </div>

    <footer id="footer">
      <p>Calculadora criada pelo <strong>LaBiOmicS</strong> </br> Laboratório de Bioinformática e Ciências Ômicas </br> <strong>Universidade de Mogi das Cruzes</strong>.</p>
    </footer>
  </div>
  <script src="popup.js"></script>
</body>
</html>
EOL

cat > imccalc/popup.js <<EOL
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('app-name').innerText = chrome.i18n.getMessage("appName");
    document.getElementById('bmi-header').innerText = chrome.i18n.getMessage("bmiHeader");
    document.getElementById('weight-label').innerText = chrome.i18n.getMessage("weightPlaceholder");
    document.getElementById('bmi-weight').placeholder = chrome.i18n.getMessage("weightPlaceholder");
    document.getElementById('height-label').innerText = chrome.i18n.getMessage("heightPlaceholder");
    document.getElementById('bmi-height').placeholder = chrome.i18n.getMessage("heightPlaceholder");
    document.getElementById('calculate-bmi').innerText = chrome.i18n.getMessage("calculateButton");
    document.getElementById('settings-text').innerText = chrome.i18n.getMessage("settingsText");

    const savedTheme = localStorage.getItem('theme') || 'light';
    setTheme(savedTheme);

    document.getElementById('theme-dropdown').addEventListener('change', function() {
        setTheme(document.getElementById('theme-dropdown').value);
    });

    document.getElementById('settings-text').addEventListener('click', function() {
        document.getElementById('modal-overlay').style.display = 'block';
        document.getElementById('settings-modal').style.display = 'block';
    });

    document.getElementById('modal-overlay').addEventListener('click', function() {
        document.getElementById('modal-overlay').style.display = 'none';
        document.getElementById('settings-modal').style.display = 'none';
    });

    document.getElementById('export-csv').addEventListener('click', exportToCSV);
    document.getElementById('delete-db').addEventListener('click', clearDatabase);
});

function setTheme(theme) {
    if (theme === 'dark') {
        document.body.classList.add('dark-theme');
        document.getElementById('bmi-result').style.color = "white"; // Apenas a cor da letra no tema escuro
        localStorage.setItem('theme', 'dark');
    } else {
        document.body.classList.remove('dark-theme');
        document.getElementById('bmi-result').style.color = "#333"; // Cor normal no tema claro
        localStorage.setItem('theme', 'light');
    }
}

let db;
const request = indexedDB.open("IMC_Calculations", 1);

request.onupgradeneeded = function(event) {
    db = event.target.result;
    const objectStore = db.createObjectStore("calculations", { keyPath: "id", autoIncrement: true });
    objectStore.createIndex("bmi", "bmi", { unique: false });
    objectStore.createIndex("timestamp", "timestamp", { unique: false });
    objectStore.createIndex("weight", "weight", { unique: false });
    objectStore.createIndex("height", "height", { unique: false });
    objectStore.createIndex("classification", "classification", { unique: false });
};

request.onsuccess = function(event) {
    db = event.target.result;
};

document.getElementById('calculate-bmi').addEventListener('click', function() {
    let weight = parseFloat(document.getElementById('bmi-weight').value);
    let height = parseFloat(document.getElementById('bmi-height').value);

    if (isNaN(weight) || isNaN(height)) {
        document.getElementById('bmi-result').innerText = chrome.i18n.getMessage("bmiError");
        return;
    }

    let bmi = weight / ((height / 100) * (height / 100));
    bmi = parseFloat(bmi.toFixed(1));  // Arredonda o IMC para 1 casa decimal

    let classification = getBMIClassification(bmi);
    let classificationColor = getBMIClassificationColor(bmi);

    let resultMessage = chrome.i18n.getMessage("bmiResult").replace("{0}", bmi.toFixed(1));
    document.getElementById('bmi-result').innerText = resultMessage;

    let classificationBox = document.getElementById('bmi-classification');
    classificationBox.innerText = classification;
    classificationBox.style.backgroundColor = classificationColor;
    classificationBox.style.display = 'block';

    const transaction = db.transaction(["calculations"], "readwrite");
    const store = transaction.objectStore("calculations");
    const timestamp = new Date().toISOString();
    store.add({ bmi: bmi, weight: weight, height: height, classification: classification, timestamp: timestamp });
});

function getBMIClassification(bmi) {
    if (bmi < 16.5) {
        return "Subnutrição ou Magreza grave";
    } else if (bmi >= 16.5 && bmi <= 18.4) {
        return "Magreza";
    } else if (bmi >= 18.5 && bmi <= 24.9) {
        return "Peso normal";
    } else if (bmi >= 25 && bmi <= 29.9) {
        return "Sobrepeso";
    } else if (bmi >= 30 && bmi <= 34.9) {
        return "Obesidade grau 1";
    } else if (bmi >= 35 && bmi <= 39.9) {
        return "Obesidade grau 2";
    } else {
        return "Obesidade grau 3";
    }
}

function getBMIClassificationColor(bmi) {
    if (bmi < 16.5) {
        return "#ff4d4d"; // Vermelho intenso
    } else if (bmi >= 16.5 && bmi <= 18.4) {
        return "#ffcc00"; // Amarelo
    } else if (bmi >= 18.5 && bmi <= 24.9) {
        return "#66cc66"; // Verde
    } else if (bmi >= 25 && bmi <= 29.9) {
        return "#ff9900"; // Laranja
    } else if (bmi >= 30 && bmi <= 34.9) {
        return "#ff6600"; // Laranja mais intenso
    } else if (bmi >= 35 && bmi <= 39.9) {
        return "#ff3300"; // Laranja avermelhado
    } else {
        return "#cc0000"; // Vermelho escuro
    }
}

function exportToCSV() {
    const transaction = db.transaction(["calculations"], "readonly");
    const store = transaction.objectStore("calculations");

    let csvContent = "data:text/csv;charset=utf-8,ID,Peso,Altura,IMC,Classificação,Data/Hora\n";
    store.openCursor().onsuccess = function(event) {
        const cursor = event.target.result;
        if (cursor) {
            csvContent += cursor.key + "," + cursor.value.weight + "," + cursor.value.height + "," +
                cursor.value.bmi.toFixed(1) + "," + cursor.value.classification + "," + cursor.value.timestamp + "\n";
            cursor.continue();
        } else {
            const encodedUri = encodeURI(csvContent);
            const link = document.createElement("a");
            link.setAttribute("href", encodedUri);
            link.setAttribute("download", "imc_calculations.csv");
            document.body.appendChild(link);
            link.click();
        }
    };
}

function clearDatabase() {
    const transaction = db.transaction(["calculations"], "readwrite");
    const store = transaction.objectStore("calculations");
    const clearRequest = store.clear();
    clearRequest.onsuccess = function() {
        alert(chrome.i18n.getMessage("clearSuccess"));
    };
}
EOL

cat > imccalc/styles.css <<EOL
body {
  font-family: 'Arial', sans-serif;
  margin: 0;
  padding: 20px;
  background-color: #f1f1f1;
  color: #333;
}

#container {
  width: 350px;
  margin: 0 auto;
  padding: 20px;
  background-color: #fff;
  border-radius: 10px;
  box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.1);
  text-align: center;
}

h1, h2 {
  color: #4CAF50;
  margin-bottom: 20px;
}

button {
  margin: 10px 0;
  padding: 10px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  width: 100%;
  font-size: 16px;
  font-weight: bold;
}

button:hover {
  background-color: #45a049;
}

input {
  padding: 10px;
  margin: 10px 0;
  width: 90%;
  border: 1px solid #ccc;
  border-radius: 5px;
  font-size: 16px;
}

#bmi-result {
  margin-top: 15px;
  font-size: 1.2em;
  font-weight: bold;
  color: #333;
}

#bmi-classification {
  margin-top: 10px;
  padding: 10px;
  font-size: 1em;
  font-weight: bold;
  color: white;
  border-radius: 5px;
}

#theme-toggle {
  margin-top: 15px;
}

#settings-text {
  margin-top: 20px;
  cursor: pointer;
}

#settings-modal {
  display: none;
  position: fixed;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  background-color: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
  z-index: 100;
}

#modal-overlay {
  display: none;
  position: fixed;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 99;
}

.modal-button {
  margin: 10px 0;
  padding: 10px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  width: 100%;
  font-size: 16px;
  font-weight: bold;
}

.modal-button:hover {
  background-color: #45a049;
}

.dark-theme {
  background-color: #333;
  color: #f4f4f4;
}

.dark-theme #container {
  background-color: #444;
  box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.5);
}

.dark-theme h1, .dark-theme h2 {
  color: #00c853;
}

.dark-theme input {
  background-color: #555;
  color: #fff;
  border: 1px solid #777;
}

.dark-theme button {
  background-color: #00c853;
  color: #fff;
}

.dark-theme button:hover {
  background-color: #00a73a;
}

.dark-theme #bmi-result {
  color: white;
}

.dark-theme #footer {
  color: #bbb;
}

.dark-theme #footer strong {
  color: #00c853;
}
EOL

cat > imccalc/_locales/pt_BR/messages.json <<EOL
{
  "appName": {
    "message": "IMCCalc"
  },
  "bmiHeader": {
    "message": "Calculadora de IMC"
  },
  "weightPlaceholder": {
    "message": "Peso (kg)"
  },
  "heightPlaceholder": {
    "message": "Altura (cm)"
  },
  "calculateButton": {
    "message": "Calcular"
  },
  "bmiError": {
    "message": "Por favor, insira peso e altura válidos."
  },
  "bmiResult": {
    "message": "Seu IMC é {0}."
  },
  "settingsText": {
    "message": "Configurações"
  },
  "clearSuccess": {
    "message": "Todos os dados foram apagados!"
  },
  "darkTheme": {
    "message": "Tema Escuro"
  },
  "lightTheme": {
    "message": "Tema Claro"
  }
}
EOL

cat > imccalc/_locales/en/messages.json <<EOL
{
  "appName": {
    "message": "IMCCalc"
  },
  "bmiHeader": {
    "message": "BMI Calculator"
  },
  "weightPlaceholder": {
    "message": "Weight (kg)"
  },
  "heightPlaceholder": {
    "message": "Height (cm)"
  },
  "calculateButton": {
    "message": "Calculate"
  },
  "bmiError": {
    "message": "Please enter valid weight and height."
  },
  "bmiResult": {
    "message": "Your BMI is {0}."
  },
  "settingsText": {
    "message": "Settings"
  },
  "clearSuccess": {
    "message": "All data has been cleared!"
  },
  "darkTheme": {
    "message": "Dark Theme"
  },
  "lightTheme": {
    "message": "Light Theme"
  }
}
EOL

cat > imccalc/_locales/es/messages.json <<EOL
{
  "appName": {
    "message": "IMCCalc"
  },
  "bmiHeader": {
    "message": "Calculadora de IMC"
  },
  "weightPlaceholder": {
    "message": "Peso (kg)"
  },
  "heightPlaceholder": {
    "message": "Altura (cm)"
  },
  "calculateButton": {
    "message": "Calcular"
  },
  "bmiError": {
    "message": "Por favor, ingrese peso y altura válidos."
  },
  "bmiResult": {
    "message": "Tu IMC es {0}."
  },
  "settingsText": {
    "message": "Configuraciones"
  },
  "clearSuccess": {
    "message": "¡Todos los datos han sido borrados!"
  },
  "darkTheme": {
    "message": "Tema Oscuro"
  },
  "lightTheme": {
    "message": "Tema Claro"
  }
}
EOL

echo "Extensão IMCCalc atualizada com sucesso!"
