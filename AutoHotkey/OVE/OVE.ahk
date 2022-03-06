;@Ahk2Exe-SetDescription Script que executa comandos customizados para os arquivos e pastas.
;@Ahk2Exe-SetVersion 3.0.1.0
;@Ahk2Exe-SetName OVE
;@Ahk2Exe-SetCopyright Script feito por Rafael Teixeira.

/*
  OVE (Open-View-Edit)
  Esta é a versão em AutoHotkey do script criado inicialmente em Batch Script, e depois em VBScript.
  Este é o script que atua como 'controller', apenas acionando as ações definidas em um arquivo .ini.
*/

#SingleInstance Off
DetectHiddenText, on
SetBatchLines, -1

OVE.IniciarPrograma()
OVE.ExecutarOVE()
return

#Include <CGUI\CGUI>
#Include <LibArquivos>
#Include <IniReader>
#Include GuiPerguntarNovaAcao.ahk
#Include GuiNovaAcao.ahk
#Include GuiListarAcoes.ahk

class OVE {
	static acao			:=	""
	static tamanhoFonte	:=	16
	static paraTodos	:=	True
	static localIni		:=	ConcatenarCaminho(True, A_ScriptDir, "Config OVE.ini")
	static arquivoAtual	:=	""
	static objIniReader	:=	""

	IniciarPrograma(){
		OVE.Validar()
		OVE.CriarArquivoConfiguracao()
		OVE.ConfigurarVariaveisAmbiente()
		OVE.objIniReader	:=	new IniReader(OVE.localIni, True, False, True, 1)
	}

	Normal(){
		for indice, arquivo in A_Args
		{
			if (indice < 2)
				Continue
			else {
				arquivoSanitizado		:=	OVE.SanitizarArgumento(arquivo)
				;
				if (OVE.acao == "-la"){
					objGuiListarAcoes	:=	new GuiListarAcoes(arquivoSanitizado)
					WinWaitClose, % "ahk_id " . objGuiListarAcoes.hwnd
					OVE.acao			:=	objGuiListarAcoes.acao
					OVE.paraTodos		:=	objGuiListarAcoes.paraTodos
				}
				;
				if (SubStr(arquivo, -3) == ".lnk") {
					; Em casos de atalhos do Windows, eu "abro" ele, para recuperar 
					; o destino dele e os seus argumentos.
					FileGetShortcut, %arquivoSanitizado%, destino, , argumentos
					OVE.ExecutarComando(OVE.RecuperarComando(OVE.acao, destino), argumentos, destino)
				} else{
					OVE.ExecutarComando(OVE.RecuperarComando(OVE.acao, arquivoSanitizado), "", arquivoSanitizado)
				}
				;
				if (!OVE.paraTodos)
					OVE.acao			:=	"-la"
			}
		}
	}

	ComParametros(){
		argumentos			:=	""
		;
		for indice, arquivo in A_Args
		{
			if (indice < 3)
				Continue
			else {
				OVE.arquivoAtual	:=	arquivo
				argumentos			.=	OVE.AdicionarArgumento(OVE.SanitizarArgumento(arquivo))
			}
		}
		;
		OVE.ExecutarComando(OVE.RecuperarComando(SubStr(OVE.acao, 1, -2), A_Args[2])
							,	argumentos
							,	A_Args[2])
	}

	; Aqui será recuperada a extensão do arquivo.
	; - Em casos de pastas, é usada uma "extensao" padrão chamada "Pastas"
	; - Em casos de arquivos:
	;   - Caso o arquivo tenha extensão, simplesmente o retorna;
	;   - Caso o arquivo não tenha, usa-se uma máscara padrão do tipo "\<nome do arquivo>"
	RecuperarExtensao(arquivo){
		; Uma pasta não necessariamente terá só o atributo de pasta,
		; pode ter outros, e nesses casos o programa não identificaria como pasta.
		if (FileExist(arquivo) ~= "D")
			return ":Pastas"
		else {
			SplitPath, arquivo, nomeArquivo, , extensao
			StringLower, extensao, extensao
			;
			if (extensao == "")
				return ("\" . nomeArquivo)
			else
				return ("." . extensao)
		}
	}

	/*  Novidade na versão 2.5.0.0 do OVE:
	  Executar um comando específico já definido, sem precisar identificar a extensão do arquivo em questão.
	  Na ação põe como sufixo a extensão que deseja executar o comando.

	  A partir daí neste modo tudo que for passado será entendido como argumento para o comando já configurado.
	*/
	AcaoEExtensaoDefinida(){
		posicaoPonto		:=	RegExMatch(OVE.acao, ":Pastas|\..*|\\.*")
		acaoSemExtensao		:=	SubStr(OVE.acao, 1, posicaoPonto-1)
		extensao			:=	SubStr(OVE.acao, posicaoPonto)
		argumentos			:=	""
		;
		for indice, arquivo in A_Args
		{
			if (indice < 2)
				Continue
			else
				argumentos	.=	OVE.AdicionarArgumento(OVE.SanitizarArgumento(arquivo))
		}
		;
		OVE.ExecutarComando(OVE.RecuperarComandoEspecifico(acaoSemExtensao, extensao, True, True)
							,	argumentos
							,	"")
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
		  - Porém, eu só vou poder perguntar caso haja permissão para perguntar.
			- É possível desabilitar individualmente (só para aquela extensão).
			  - Força esta extensão a rodar sempre o comando global.
			- É possível desabilitar globalmente (para todas as extensões).
			  - Todas as extensões sem comando específico vão rodar este comando global.
		- Caso configure um comando específico, este será rodado. Caso contrário, será rodado o comando
		  global.
	  3. Em casos em que não há nem um comando específico, nem um comando global, será dada a possibilidade
		 de criar um comando específico para aquela extensão (mas que pode vir a ser global da ação).
	*/
	RecuperarComando(acao, arquivo){
		extensao			:=	OVE.RecuperarExtensao(arquivo)
		;
		comandoEspecifico	:=	OVE.RecuperarComandoEspecifico(acao, extensao, False, False)
		if (OVE.EhComandoValido(comandoEspecifico, True))
			return comandoEspecifico
		;
		novoComando			:=	""
		comandoGlobal		:=	OVE.RecuperarComandoGlobal(acao)
		if (OVE.EhComandoValido(comandoGlobal, True)){
			if (OVE.CadastraAcaoNova(acao, extensao, arquivo, True, novoComando))
				return novoComando
			else
				return comandoGlobal
		} else {
			if (OVE.CadastraAcaoNova(acao, extensao, arquivo, False, novoComando))
				return novoComando
			else
				return ""
		}
	}

	CadastraAcaoNova(acao, extensao, arquivo, temAcaoGlobal, ByRef novoComando){
		if (temAcaoGlobal)
			if (!OVE.TemPermissaoParaPerguntar(acao, extensao))
				return False
		;
		objGuiPerguntarAcaoNova			:=	new GuiPerguntarNovaAcao(temAcaoGlobal, acao, extensao)
		WinWaitClose, % "ahk_id " . objGuiPerguntarAcaoNova.hwnd
		if (objGuiPerguntarAcaoNova.querCadastrar) {
			objGuiNovaAcao				:=	new GuiNovaAcao(arquivo, extensao, acao, temAcaoGlobal)
			WinWaitClose, % "ahk_id " . objGuiNovaAcao.hwnd
			novoComando					:=	objGuiNovaAcao.novaAcao
			return True
		} else
			return False
	}

	TemPermissaoParaPerguntar(acao, extensao){
		permissaoCadComandoEspecGlobal	:=	OVE.objIniReader.RecuperarChaveValor(acao, "permissaoCadComandoEspec*", "S")
		permissaoCadComandoEspecExtens	:=	OVE.objIniReader.RecuperarChaveValor(acao, "permissaoCadComandoEspec" . extensao, "S")
		;
		return (permissaoCadComandoEspecGlobal == "S" and permissaoCadComandoEspecExtens == "S")
	}

	RecuperarComandoGlobal(acao){
		comandoRecuperado	:=	OVE.objIniReader.RecuperarChaveValor(acao, "*")
		return comandoRecuperado
	}

	; No novo modo criado na versão 2.5.0.0 do OVE será preciso já existir um comando específico
	; para a combinação (ação+extensão).
	; Caso não exista, deve-se configurar previamente.
	RecuperarComandoEspecifico(acao, extensao, ehFatal := True, exibeMensagem := True){
		comandoRecuperado	:=	OVE.objIniReader.RecuperarChaveValor(acao, extensao)
		;
		if (comandoRecuperado == "ERROR"){
			if (exibeMensagem)
				MsgBox 0x10, Erro, Não existe comando específico cadastrado para a combinação %acao%%extensao%.
			if (ehFatal)
				ExitApp
		}
		;
		return comandoRecuperado
	}

	; Esta é a função que efetivamente executará os comandos vindos das associações.
	ExecutarComando(comando, argumentos, arquivo := ""){
		if (!OVE.EhComandoValido(comando))
			return
		;
		if (arquivo == "") {
			comando		:=	StrReplace(comando, "###", argumentos)
		} else {
			comando		:=	StrReplace(comando, "###", """" . arquivo . """")
			if (Trim(argumentos) != "")
				comando	.=	" " . argumentos
		}
		;
		try {
			if (arquivo == "")
				Run, %comando%, , , outPID
			else {
				if (FileExist(arquivo) ~= "D")
					diretorioTrabalho	:= arquivo
				else
					SplitPath, arquivo, , diretorioTrabalho
				;
				Run, %comando%, %diretorioTrabalho%, , outPID
			}
		} catch {
			WinKill, ahk_pid %outPID%
			MsgBox,
			(
    Erro ao executar comando.

Verifique o comando executado.
Comando: %comando%
			)
			exitapp
		}
	}

	EhComandoValido(comando, vazioVale := False){
		if (comando == "ERROR")
			return False
		;
		if (!vazioVale){
			if (Trim(comando) == "")
				return False
		}
		;
		return True
	}

	AdicionarArgumento(arg){
		strNovoArg		:=	""
		;
		if (InStr(arg, " "))
			strNovoArg	:=	"""" . arg . """ "
		else
			strNovoArg	:=	arg . " "
		;
		return strNovoArg
	}

	SanitizarArgumento(arg){
		if (SubStr(arg, 0) == """")
			return SubStr(arg, 1, -1)
		else
			return arg
	}

	ExecutarOVE(){
		funcExecutar		:=	{}
		;
		if (SubStr(OVE.acao, -1) == "-p")
			funcExecutar	:=	ObjBindMethod(OVE, "ComParametros")
		else if (RegExMatch(OVE.acao, ":Pastas|\..*|\\.*"))
			funcExecutar	:=	ObjBindMethod(OVE, "AcaoEExtensaoDefinida")
		else
			funcExecutar	:=	ObjBindMethod(OVE, "Normal")
		;
		%funcExecutar%()
		OVE.objIniReader.SalvarIni()
		ExitApp
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
	; - Um ação, que pode ser:
	;   - Uma combinação de letras e números, ou;
	;   - -la, que é uma ação especial, que listará todos as ações já configuradas.
	; - E uma lista de arquivos (com pelo menos 1 arquivo).
	; Porém, a ação pode ter também o sufixo '-p'. Com ele, é passado:
	;		- Somente 1 arquivo;
	;		- Argumentos, que serão aplicados sobre este arquivo.
	;		Neste modo, será executado o comando associado a ação (que é de mesmo nome, sem
	;		os 2 últimos caracteres), embutindo tais parâmetros nesse comando
    Validar(){
        if (A_Args.Length() < 2)
            OVE.Erro()
		if (!(A_Args[1] ~= "^[a-zA-Z0-9]+(-p|:Pastas|\\.*|\..*|$)|^-la$"))
			OVE.Erro()
		OVE.acao	:=	A_Args[1]
    }

	; Na primeira execução do programa, o arquivo de configuração não existirá.
	; Com isso, ele será criado neste momento.
	CriarArquivoConfiguracao(){
		if (!FileExist(OVE.localIni)){
			FileAppend, , % OVE.localIni, UTF-8-RAW
		}
	}

	; Mensagem de erro, informando que deve ser passado, pelo menos, 1 parâmetro de ação e 1 parâmetro de arquivo/argumento,
	; para o script ser executado.
    Erro(){
        msg = 
  (
    Não foi passada ação ou arquivo para o programa.

O programa deve ser usado da seguinte forma:
1) OVE acao arquivo1 [arquivo2 arquivo3 ...]
OU
2) OVE -la arquivo1 [arquivo2 arquivo3 ...]
OU
3) OVE acao-p arquivo [argumento1 argumento2 argumento3 ...]
OU
4) OVE combinacao argumento1 [argumento2 argumento3 ...]

Explicação dos modos:
1) Modo normal, onde todos os arquivos passados serão executados sob a ação 'acao';
2) Modo em que é possível escolher ou criar uma nova ação, e ela será usada nos arquivos passados;
3) Modo especial, que permite anexar argumentos ao final do comando configurado para a extensão na ação;
4) Modo mais poderoso que o 3), pois permite anexar argumentos em qualquer ordem, pois o comando que será executado está definido em 'combinacao'.

Observações:
- 'acao' é um termo que contém somente letras (sem acentos) e números.
- 'combinacao' é definido como: acao+extensao
  - Onde 'extensao' pode ser:
    - A extensão normal de um arquivo (incluindo o ponto '.');
    - `\nomeArquivo`, caso o arquivo não tenha uma extensão, ou;
    - `:Pastas`, para se referir as pastas e diretórios em geral.
)
	MsgBox, 16, OVE, %msg%
	exitapp
    }
}