document.addEventListener('DOMContentLoaded', function() {
    // Carregar as mensagens de internacionalização
    document.getElementById('app-name').innerText = chrome.i18n.getMessage("appName");
    document.getElementById('bmi-header').innerText = chrome.i18n.getMessage("bmiHeader");
    document.getElementById('weight-label').innerText = chrome.i18n.getMessage("weightPlaceholder");
    document.getElementById('bmi-weight').placeholder = chrome.i18n.getMessage("weightPlaceholder");
    document.getElementById('height-label').innerText = chrome.i18n.getMessage("heightPlaceholder");
    document.getElementById('bmi-height').placeholder = chrome.i18n.getMessage("heightPlaceholder");
    document.getElementById('calculate-bmi').innerText = chrome.i18n.getMessage("calculateButton");

    // Garantir que os textos de tema apareçam no dropdown
    document.getElementById('theme-dropdown-label').innerText = chrome.i18n.getMessage("themeDropdownLabel");
    document.getElementById('light-theme-option').innerText = chrome.i18n.getMessage("lightTheme");
    document.getElementById('dark-theme-option').innerText = chrome.i18n.getMessage("darkTheme");

    document.getElementById('export-csv').innerText = chrome.i18n.getMessage("exportCSV");
    document.getElementById('delete-db').innerText = chrome.i18n.getMessage("clearData");

    const savedTheme = localStorage.getItem('theme') || 'light';
    document.getElementById('theme-dropdown').value = savedTheme;
    setTheme(savedTheme);

    document.getElementById('theme-dropdown').addEventListener('change', function() {
        setTheme(document.getElementById('theme-dropdown').value);
    });

    // Cálculo do IMC
    document.getElementById('calculate-bmi').addEventListener('click', function() {
        let weight = parseFloat(document.getElementById('bmi-weight').value);
        let height = parseFloat(document.getElementById('bmi-height').value);

        if (isNaN(weight) || isNaN(height)) {
            document.getElementById('bmi-result').innerText = chrome.i18n.getMessage("bmiError");
            return;
        }

        let bmi = weight / ((height / 100) * (height / 100));
        bmi = parseFloat(bmi.toFixed(1));  // Arredondar para 1 casa decimal

        let classification = getBMIClassification(bmi);
        let classificationColor = getBMIClassificationColor(bmi);

        let resultMessage = chrome.i18n.getMessage("bmiResult").replace("{0}", bmi.toFixed(1));
        document.getElementById('bmi-result').innerText = resultMessage;

        let classificationBox = document.getElementById('bmi-classification');
        classificationBox.innerText = classification;
        classificationBox.style.backgroundColor = classificationColor;
        classificationBox.style.display = 'block';

        persistCalculation(bmi, weight, height, classification);
    });

    // Exportar CSV e apagar dados
    document.getElementById('export-csv').addEventListener('click', exportToCSV);
    document.getElementById('delete-db').addEventListener('click', clearDatabase);
});

// Função para mudar o tema
function setTheme(theme) {
    if (theme === 'dark') {
        document.body.classList.add('dark-theme');
        document.getElementById('bmi-result').style.color = "white"; // Cor branca no tema escuro
        localStorage.setItem('theme', 'dark');
    } else {
        document.body.classList.remove('dark-theme');
        document.getElementById('bmi-result').style.color = "#333"; // Cor normal no tema claro
        localStorage.setItem('theme', 'light');
    }
}

// Função para classificar o IMC
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

// Função para cor da classificação do IMC
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
        return "#ff6600"; // Laranja intenso
    } else if (bmi >= 35 && bmi <= 39.9) {
        return "#ff3300"; // Laranja avermelhado
    } else {
        return "#cc0000"; // Vermelho escuro
    }
}

// IndexedDB para persistência dos dados
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

// Persistir cálculo no IndexedDB
function persistCalculation(bmi, weight, height, classification) {
    const transaction = db.transaction(["calculations"], "readwrite");
    const store = transaction.objectStore("calculations");
    const timestamp = new Date().toISOString();
    store.add({ bmi: bmi, weight: weight, height: height, classification: classification, timestamp: timestamp });
}

// Exportar os dados para CSV
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

// Apagar os dados do IndexedDB
function clearDatabase() {
    const transaction = db.transaction(["calculations"], "readwrite");
    const store = transaction.objectStore("calculations");
    const clearRequest = store.clear();
    clearRequest.onsuccess = function() {
        alert(chrome.i18n.getMessage("clearSuccess"));
    };
}
