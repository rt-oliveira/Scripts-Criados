/*
	Nos casos em n�o h� comando espec�fico configura��o para a combina��o (a��o+extens�o),
	ser� mostrada uma tela, que ser� perguntado se deseja criar um comando, que pode ser
	espec�fico, ou at� mesmo global.
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
		A a��o %acao% tem um comando global, 
mas n�o h� um comando espec�fico para a extens�o %extensao%.

Deseja cadastrar um comando espec�fico para esta extens�o?
		)
	} else {
		Gui, PerguntaAcaoNaoDefinida:Add, Text, ,
		(
		N�o est� definido um comando espec�fico para a combina��o %acao%%extensao%.
		
Deseja definir agora?
		)
	}
	Gui, Add, Button, w500 Default gCadastrarAcao, Sim
	Gui, Add, Button, w500 gNaoCadastrarAcao, N�o
	if (temAcaoGlobal)
		Gui, Add, Button, w500 gNaoCadastrarNaoPerguntar, N�o, e n�o pergunte novamente
	Gui, -MaximizeBox AlwaysOnTop
	if (temAcaoGlobal)
		Gui, Show, , Comando espec�fico n�o definido
	else
		Gui, Show, , Comando n�o definido
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
IniWrite, N, %localIni%, %acao%, permissaoCadComandoEspec
vaiCriarAcao := "N"
Gui, Destroy
Pause, Off
return
}

/*
	Querendo criar comando, abre-se uma nova tela, perguntando qual o
	comando que deseja configurar.
	
	Pode configurar tanto um comando global (em casos de n�o exist�ncia),
	como comandos espec�ficos (quando h� o primeiro, mas n�o h� o �ltimo).
*/
CriarComandoAcao(arquivo, extensao, temAcaoGlobal){
	static comando
	comando := "ERROR"
	;
	Gui, CadAcoes:Default
	;
	Gui, Font, s%tamanhoFonte%, MS Sans Serif
	if (FileExist(arquivo) == "D")
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
				Gui, Add, Text, , Copiar associa��o de:
				Gui, Add, ListView, gCopiaComando -WantF2 Grid w800 NoSortHdr Sort r10 x+m, Associa��o|Comando
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
		Gui, Add, CheckBox, xm, Comando global da a��o %acao%
	Gui, Add, Text, xm, Dica: a m�scara ### pode ser usada. Ela ser� substitu�da pelo caminho do arquivo/pasta.
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
		if (ehComandoGlobal)
			IniWrite, %comando%, %localIni%, %acao%, %acao%*
		else
			IniWrite, %comando%, %localIni%, %acao%, %acao%%extensao%
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
		if (ehComandoGlobal)
			IniWrite, %comandoDigitado%, %localIni%, %acao%, %acao%*
		else
			IniWrite, %comandoDigitado%, %localIni%, %acao%, %acao%%extensao%
		;
		Gui, Destroy
		Pause, Off
	}
}

ehValidoNovoComando(comandoDigitado){
	if (Trim(comandoDigitado) == ""){
		msgbox, 36, , Confirma a inclus�o de comando vazio?
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
