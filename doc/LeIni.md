# LeIni

## Descrição

Esse script, que é um pequeno programa, foi criado para ajudar na leitura de arquivos .ini.

## Motivação

Os arquivos de extensão .ini são criados, geralmente, para guardar configurações de programas. Eles costumam ter o seguinte padrão:

```ini
[seção1]
conf1=valor1
conf2=valor2

[seção2]
conf3=valor3
conf4=valor4
```

Em geral, nos inícios dos programas que possuem arquivos dessa extensão há rotinas que leem esses arquivos, de modo a recuperar as configurações descritas, e assim pode usar em sua aplicação.

Contudo, em algumas linguagens de programação não há funções nativas que suportem a leitura desse tipo de arquivo.

Para esses casos o script foi criado. Com ele, será possível ler um arquivo .ini, para recuperar o valor de uma chave de uma seção específica.

## Como executar o script?

O programa é chamado da seguinte forma:

```
LeIni *arquivo* *seção* *chave*
```

- Onde:
    + *arquivo* é o caminho do arquivo .ini;
    + *seção* é o nome da seção na qual está se referindo;
    + *chave* e a chave da seção que quer recuperar seu valor;

- O script retorna:
    + Em caso de não achar *chave* em *seção*: código de saída 1;
    + Em caso de achar *chave* em *seção*: o valor daquela chave e código de saída 0;
    + Em caso de não localizar *arquivo*: código de saída 5.

---

[Código-fonte do programa](C%2B%2B/LeIni.cpp)
