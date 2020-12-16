#include <iostream>
#include <fstream>
#include <locale>
using namespace std;

void arquivoExiste();

string arquivo, secao, chave, linha;
string chaveLinha, conteudo;
bool acheiSecao;
ifstream arq;

/* C�digos de retorno:
	0 - Achou
	1 - N�o achou
	5 - N�o existe arquivo
*/

int main(int argc, char** argv){
	setlocale(LC_ALL,"Portuguese");
	arquivo = argv[1];	
	secao = argv[2];
	secao = "[" + secao + "]";
	chave = argv[3];
	
	arquivoExiste();
	
	acheiSecao = false;
	
	while(!arq.eof()){
		getline(arq, linha);
		if (linha.length() > 0){
			if (acheiSecao){
				if (linha.at(0) == '['){
					arq.close();
					exit(1);
				} else {
					chaveLinha = linha.substr(0, linha.find('='));
					conteudo = linha.substr(linha.find('=')+1);
					if (chave.compare(chaveLinha) == 0){
						cout<<conteudo;
						arq.close();
						exit(0);
					}
				}
			} else{
				if (linha.compare(secao)==0)
					acheiSecao = true;
				else
					acheiSecao = false;	
			}
		}
	}
	arq.close();
	return 1;
}

void arquivoExiste(){
	arq.open(arquivo.c_str());
	if (arq.fail()){
		cout<<arquivo<<" n�o existe."<<endl<<endl;
		system("pause");
		exit(5);
	}
}

