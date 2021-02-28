;@Ahk2Exe-SetDescription Script que executa comandos customizados para os arquivos e pastas.
;@Ahk2Exe-SetVersion 2.2.2.0
;@Ahk2Exe-SetName OVE
;@Ahk2Exe-SetCopyright Script feito por Rafael Teixeira.

/*
  OVE (Open-View-Edit)
  Esta é a versão em AutoHotkey do script criado inicialmente em Batch Script, e depois em VBScript.
  Este é o script que atua como 'controller', apenas acionando as ações definidas em um arquivo .ini.
*/

#SingleInstance Off
#Warn UseUnsetLocal
DetectHiddenText, on

Testar()

; Três variáveis globais
global acao, localIni, ParaTodos
ParaTodos := True
global tamanhoFonte := 16
;
; Na primeira execução do programa, o arquivo de configuração não existirá.
; Com isso, ele será criado neste momento.
localIni = %A_ScriptDir%\Config OVE.ini
if (!FileExist(localIni))
  FileAppend, , %localIni%, UTF-8-RAW
;
ConfigurarVariaveisAmbiente()
;
for i, arquivo in A_Args
{
	if (i == 1)
		continue
	else{
		if (acao == "-la")
          acao := ListarAcoes(arquivo)
		;
		if (SubStr(arquivo, -3) == ".lnk") {
          ; Em casos de atalhos do Windows, eu "abro" ele, para recuperar 
          ; o destino dele e os seus argumentos.
          FileGetShortcut, %arquivo%, destino, , argumentos
          RecuperarEExecutarComando(acao, destino, argumentos)
        } else
          RecuperarEExecutarComando(acao, arquivo)
		;
		if (!ParaTodos)
			acao := "-la"
	}
}
exitapp
	
;----------------------------------------------------------------

; Esta é a função que efetivamente executará os comandos vindos das associações.
ExecutarComando(comando, arquivo, argumentos := ""){
  if (trim(comando) == "")
    return
  ;
  comando := StrReplace(comando, "###", """" arquivo """")
  if (trim(argumentos) <> "")
    comando := comando . " " . argumentos
  ;
  try
  {
    Run, %comando%, , , outPID
  }
  catch
  {
    WinKill, ahk_pid %outPID%
    msgbox, 
    (
    Erro ao executar comando.
          
Verifique o comando executado.
Comando: %comando%
    )
    exitapp
  }
}

; Aqui será recuperada a extensão do arquivo.
; - Em casos de pastas, é usada uma "extensao" padrão chamada "Pastas"
; - Em casos de arquivos:
;   - Caso o arquivo tenha extensão, simplesmente o retorna;
;   - Caso o arquivo não tenha, usa-se uma máscara padrão do tipo "\<nome do arquivo>"
RecuperarExtensao(arquivo){
	if (FileExist(arquivo) == "D")
		return "Pastas"
	else{
		SplitPath, arquivo, nomeArquivo, , tmpExt
		StringLower, tmpExt, tmpExt
		;
		return (tmpExt == "") ? "\"nomeArquivo : "."tmpExt
	}
}

/*
  Modo de funcionamento do programa em cada arquivo:
  - Há 2 tipos de comandos para cada ação:
    - Os comandos específicos, que há 1 para cada extensão; 
    - Os comandos globais, que há apenas 1 por ação. Eles são executados quando
      não há comando específico determinado para aquela extensão.
  Funcionamento:
  1. Primeiro, é visto se foi configurado um comando específico naquela ação para
     aquela extensão;
    - Havendo, simplesmente o executa;
    - Não havendo, siga para o passo 2.
  2. Em casos em que não um comando específico configurado, é visto se foi configurado
     um comando global para aquela ação.
    - Havendo, será aberta a possibilidade de poder configurar um comando específico daquela
      ação para aquela extensão
      - Caso seja permitido perguntar, pois é possível desabilitar tal opção, fazendo com que
        sempre force a executar o comando global para todas as extensões não configuradas naquela
        ação.
      - Caso configure um comando específico, este será rodado. Caso contrário, será rodado o comando
        global.
  3. Em casos em que não há nem um comando específico, nem um comando global, será dada a possibilidade
     de criar um comando específico para aquela extensão (mas que pode vir a ser global da ação).
*/
RecuperarEExecutarComando(acao, arquivo, argumentos := ""){
    extensao := RecuperarExtensao(arquivo)
	;
	IniRead, comandoRecuperado, %localIni%, %acao%, %acao%%extensao%
	comandoRecuperado = %comandoRecuperado% ; Para remover espaços em branco no início e no fim da string
	if (comandoRecuperado <> "ERROR"){
      ExecutarComando(comandoRecuperado, arquivo, argumentos)
      return
    }
    ;
    IniRead, comandoRecuperado, %localIni%, %acao%, %acao%*
    comandoRecuperado = %comandoRecuperado%
    if (comandoRecuperado <> "ERROR"){
      ;
      IniRead, permissaoCadComandoEspec, %localIni%, %acao%, permissaoCadComandoEspec, S
      if (permissaoCadComandoEspec == "S"){
        if (VaiCadastrarAcao(arquivo, extensao, True) == "S"){
          comandoCriado := CriarComandoAcao(arquivo, extensao, True)
          comandoRecuperado := (comandoCriado == "ERROR") ? comandoRecuperado : comandoCriado
        }
      }
    } else {
      ;
      comandoRecuperado := ""
      if (VaiCadastrarAcao(arquivo, extensao, False) == "S"){
        comandoCriado := CriarComandoAcao(arquivo, extensao, False)
        comandoRecuperado := (comandoCriado == "ERROR") ? comandoRecuperado : comandoCriado
      }
    }
    ;
    ExecutarComando(comandoRecuperado, arquivo, argumentos)
}

; Esta função foi criada para permitir a execução de programas sem precisar, muitas vezes,
; ficar usando o caminho completo dele no arquivo de configuração.
; A partir dessa função:
;  - Os programas que serão usados podem estar na mesma pasta onde o script está localizado.
;  - Eles podem ser referenciados apenas pelo nome do executável/atalho/...
ConfigurarVariaveisAmbiente(){
  ; Esta primeira parte permitirá aos programas poderem estar na mesma pasta do script
  ; e apenas serem referenciados no arquivo de configuração pelo seu nome.
	EnvGet, dirPath, PATH
	dirPath := dirPath ";" A_ScriptDir
	EnvSet, PATH, %dirPath%
  ;
  ; Esta segunda parte permitirá poder executar atalhos sem precisar colocar a extensão
  ; no comando. Isto é: para uma associação cujo comando use o atalho 'teste.lnk', ao invés 
  ; de usar a forma completo, usará apenas o nome do atalho, ou seja, 'teste'.
	EnvGet, varPathExt, PATHEXT
	StringLower, varPathExt, varPathExt
	if (Instr(varPathExt, ".lnk") = 0)
	{
		varPathExt := varPathExt ";.LNK"
		EnvSet, PATHEXT, %varPathExt%
	}
}

; Para o programa funcionar, é preciso passar:
; - Um comando, que pode ser:
;   - Uma ação (composta por letras e números), ou;
;   - -la, que é um argumento especial, que listará todos os comandos configurados.
; - E uma lista de arquivos (com pelo menos 1 arquivo).
Testar(){
  if ((A_Args.Length() < 2) or !(A_Args[1] ~= "^([a-zA-Z0-9]+)|(-la)$"))
    ErroOVE()
  else
    acao := A_Args[1]
}

; Mensagem de erro, informando que deve ser passado, pelo menos, 1 ação e 1 arquivo,
; para o script ser executado.
ErroOVE(){
	msg = 
  (
    Não foi passada ação ou arquivo para o programa.

O programa deve ser usado da seguinte forma:
OVE acao programa1 [programa2 programa3 ...]

Onde 'acao' pode ser:
- Um termo que contenha somente letras (sem acentos) e números, ou;
- '-la', que vai listar as ações.
  )
	MsgBox, 16, OVE, %msg%
	exitapp
}

#include ListarAcoes.ahk
#include CadAcoes.ahk