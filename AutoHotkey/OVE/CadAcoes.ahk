/*
	Nos casos em não há comando específico configuração para a extensão, será mostrada uma tela,
	que será perguntado se deseja criar um comando, que pode ser específico, ou até mesmo global.
*/
VaiCadastrarAcao(arquivo, extensao, temAcaoGlobal := False){
	global tamanhoFonte
	;
	Gui, PerguntaAcaoNaoDefinida:Default
	;
	Gui, Font, s%tamanhoFonte%, MS Sans Serif
	;
	vaiCriarAcao := ""
	;
	if (temAcaoGlobal){
		Gui, PerguntaAcaoNaoDefinida:Add, Text, ,
		(
		A ação %acao% tem um comando global, 
mas não há um comando específico para a extensão %extensao%.

Deseja cadastrar um comando específico para esta extensão?
		)
	} else {
		Gui, PerguntaAcaoNaoDefinida:Add, Text, ,
		(
		Não está definido um comando específico para a combinação %acao%%extensao%.
		
Deseja definir agora?
		)
	}
	Gui, Add, Button, w650 Default gCadastrarAcao, Sim
	Gui, Add, Button, w650 gNaoCadastrarAcao, Não
	if (temAcaoGlobal){
		Gui, Add, Button, w650 gNaoCadastrarNaoPerguntar, Não, e não pergunte novamente (para a ação %acao%)
		Gui, Add, Button, w650 gNaoCadastrarNaoPerguntarExt, Não, e não pergunte novamente (para a extensão %extensao%)
	}
	Gui, -MaximizeBox AlwaysOnTop
	if (temAcaoGlobal)
		Gui, Show, , Comando específico não definido
	else
		Gui, Show, , Comando não definido
	;
	GuiControl, Focus, Button1
	;
	Pause, On
	return vaiCriarAcao
	
PerguntaAcaoNaoDefinidaGuiClose:
PerguntaAcaoNaoDefinidaGuiEscape:
vaiCriarAcao := "N"
Gui, Destroy
Pause, Off
return

CadastrarAcao:
vaiCriarAcao := "S"
Gui, Destroy
Pause, Off
return

NaoCadastrarAcao:
vaiCriarAcao := "N"
Gui, Destroy
Pause, Off
return

NaoCadastrarNaoPerguntar:
IniWrite, N, %localIni%, %acao%, permissaoCadComandoEspec*
vaiCriarAcao := "N"
Gui, Destroy
Pause, Off
return

NaoCadastrarNaoPerguntarExt:
IniWrite, N, %localIni%, %acao%, permissaoCadComandoEspec%extensao%
vaiCriarAcao := "N"
Gui, Destroy
Pause, Off
return
}

/*
	Querendo criar comando, abre-se uma nova tela, perguntando qual o
	comando que deseja configurar.
	
	Pode configurar tanto um comando global (em casos de não existência),
	como comandos específicos (quando há o primeiro, mas não há o último).
*/
CriarComandoAcao(arquivo, extensao, temAcaoGlobal){
	static comando
	comando := "ERROR"
	;
	Gui, CadAcoes:Default
	;
	Gui, Font, s%tamanhoFonte%, MS Sans Serif
	if (FileExist(arquivo) ~= "D")
		Gui, Add, Text, , Pasta: %arquivo%
	else
		Gui, Add, Text, , Arquivo: %arquivo%
	;
	temComandoCadastrado := False
	IniRead, comandosSecao, %localIni%, %acao%
	Loop, Parse, comandosSecao, `n
	{
		commArr := StrSplit(A_LoopField, "=", , 2)
		if (commArr[1] <> (acao . "*")){
			if (!temComandoCadastrado){
				Gui, Add, Text, , Copiar associação de:
				Gui, Add, ListView, gCopiaComando -WantF2 Grid w800 NoSortHdr Sort r10 x+m, Associação|Comando
				temComandoCadastrado := !temComandoCadastrado
			}
			LV_Add("", commArr[1], commArr[2])
		}
	}
	if (temComandoCadastrado)
		LV_ModifyCol(1, "AutoHdr")
	;
	Gui, Add, Button, xm R0.5 gNovoComando, Comando:
	Gui, Add, Edit, x+m w850
	;
	if (!temComandoCadastrado)
		GuiControl, Focus, Edit1
	if (!temAcaoGlobal)
		Gui, Add, CheckBox, xm, Comando global da ação %acao%
	Gui, Add, Text, xm, Dica: a máscara ### pode ser usada. Ela será substituída pelo caminho do arquivo/pasta.
	;
	Gui, Add, Button, Hidden Default gCopiaOuNovoComando, OK
	Gui, Show, AutoSize , Cadastro de comando
	;
	Pause, On
	return comando

CadAcoesGuiClose:
CadAcoesGuiEscape:
	comando := ""
	Gui, Destroy
	Pause, Off
	return
	
CopiaComando:
	if (A_GuiEvent == "DoubleClick")
		EscreveCopiaNoIni(extensao, comando)
	return	

CopiaOuNovoComando:
	Gui, Submit, NoHide
	ControlGetFocus, controlComFoco
	if (controlComFoco == "SysListView321")
		EscreveCopiaNoIni(extensao, comando)
	else if (controlComFoco == "Edit1"){
		EscreveNovoComandoNoIni(extensao, comando)
	}
	else if (controlComFoco == "Button2"){
		linhaSelecionada := LV_GetNext()
		if (linhaSelecionada <> 0)
			EscreveCopiaNoIni(extensao, comando)
		else
			EscreveNovoComandoNoIni(extensao, comando)
	}
	return

NovoComando:
	EscreveNovoComandoNoIni(extensao, comando)
	return
}

EscreveCopiaNoIni(extensao, ByRef comando){
	linhaSelecionada := LV_GetNext()
	if (linhaSelecionada <> 0){
		LV_GetText(comando,LV_GetNext(),2)
		ControlGet, ehComandoGlobal, Checked, , Button2
		;
		EscreverComando(ehComandoGlobal, comando, extensao)
		;
		Gui, Destroy
		Pause, Off
	}
}

EscreveNovoComandoNoIni(extensao, ByRef comando){
	ControlGetText, comandoDigitado, Edit1
	;
	if (ehValidoNovoComando(comandoDigitado)){
		comando := comandoDigitado
		ControlGet, ehComandoGlobal, Checked, , Button2
		;
		EscreverComando(ehComandoGlobal, comandoDigitado, extensao)
		;
		Gui, Destroy
		Pause, Off
	}
}

ehValidoNovoComando(comandoDigitado){
	if (Trim(comandoDigitado) == ""){
		msgbox, 36, , Confirma a inclusão de comando vazio?
		IfMsgBox, Yes
			return True
		else
			return False
	} 
	;
	if (comandoDigitado != "###" and !Instr(comandoDigitado, """", , , 2)){
		msgbox, 16, , O programa deve estar entre aspas.
		return False
	}
	;
	return True
}

EscreverComando(ehComandoGlobal, comando, extensao){
	if RegExMatch(comando, """.*""")
		comando := """" . comando . """"
	;
	if (ehComandoGlobal)
		IniWrite, %comando%, %localIni%, %acao%, *
	else
		IniWrite, %comando%, %localIni%, %acao%, %extensao%
}
