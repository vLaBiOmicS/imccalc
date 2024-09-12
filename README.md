# IMC

**IMCCalc** é uma extensão do Google Chrome para calcular o Índice de Massa Corporal (IMC). A calculadora persiste os cálculos no IndexedDB e permite exportar os dados para um arquivo CSV ou apagá-los diretamente do banco de dados local. A extensão oferece suporte a múltiplos idiomas e temas (claro e escuro).

<img src="/imc.png" width="200"/>

---

## Recursos

- **Cálculo do IMC** com base no peso e altura inseridos.
- **Classificação do IMC** de acordo com as categorias estabelecidas pela OMS.
- **Persistência de dados** dos cálculos anteriores usando IndexedDB.
- **Exportação para CSV** com peso, altura, IMC e classificação.
- **Suporte a múltiplos idiomas** (Português, Inglês e Espanhol).
- **Troca de tema** entre claro e escuro através de um menu dropdown.
- **Design responsivo** adaptado para diferentes tamanhos de tela.
- **Internacionalização** completa com mensagens e textos em diferentes idiomas.
- **Notificação de tooltip** ao passar o mouse sobre o nome "LaBiOmicS", exibindo "Laboratório de Bioinformática e Ciências Ômicas da Universidade de Mogi das Cruzes".

---

## Funcionamento

<img src="/imc.gif" width="200"/>


---


## Instalação

1. Clone este repositório:
    ```bash
    git clone https://github.com/seuusuario/imccalc.git
    ```

2. No Chrome, acesse `chrome://extensions/`.

3. Ative o **Modo do desenvolvedor** no canto superior direito.

4. Clique em **Carregar sem compactação** e selecione a pasta `imccalc`.

5. A extensão será instalada e estará disponível para uso.

## Funcionalidades

### Cálculo do IMC
- O cálculo do IMC é realizado utilizando a fórmula:
    \[
    IMC = \frac{Peso(kg)}{Altura(m)^2}
    \]
- O IMC é arredondado para uma casa decimal.

### Classificação do IMC
As classificações de IMC seguem o seguinte critério:

| IMC          | Classificação                     |
|--------------|-----------------------------------|
| < 16.5       | Subnutrição ou Magreza grave      |
| 16.5 - 18.4  | Magreza                           |
| 18.5 - 24.9  | Peso normal                       |
| 25 - 29.9    | Sobrepeso                         |
| 30 - 34.9    | Obesidade grau 1                  |
| 35 - 39.9    | Obesidade grau 2                  |
| ≥ 40         | Obesidade grau 3                  |

### Exportação para CSV
A extensão permite a exportação dos cálculos realizados para um arquivo CSV. Cada entrada contém:
- **Peso** em kg
- **Altura** em cm
- **IMC**
- **Classificação**
- **Data/Hora do cálculo**

### Troca de Tema
- O usuário pode escolher entre o **Tema Claro** e o **Tema Escuro** através de um menu dropdown.
- O tema atual é salvo no `localStorage` e reaplicado ao recarregar a extensão.


## Arquivos Principais

- `manifest.json`: Descreve as permissões e configurações da extensão.
- `popup.html`: Interface principal da extensão.
- `popup.js`: Lógica de cálculo, troca de tema e manipulação do IndexedDB.
- `styles.css`: Estilos CSS para temas claro e escuro.
- Diretórios `_locales`: Arquivos de tradução para diferentes idiomas.

## Como Contribuir

1. Faça um fork do repositório.
2. Crie uma nova branch:
    ```bash
    git checkout -b minha-branch
    ```
3. Faça suas alterações e commite:
    ```bash
    git commit -m 'Descrição das mudanças'
    ```
4. Envie para a branch:
    ```bash
    git push origin minha-branch
    ```
5. Abra um Pull Request.

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

