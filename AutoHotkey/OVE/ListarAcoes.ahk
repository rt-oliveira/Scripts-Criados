; Caso 'acao' seja '-la', ser� aberta uma janela que lista as a��es j� cadastradas no
; arquivo de configura��es. O usu�rio poder� ent�o escolher uma das a��es mostradas
; para usar no arquivo atual, ou ent�o criar uma nova a��o. 
; Haver� a op��o de poder usar esta mesma a��o (escolhida/criada) para todos os pr�ximos
; arquivos passados.
ListarAcoes(arquivo){
  acaoEscolhida := ""
  ;
  IniRead, outSecoes, %localIni%
  outSecoes := StrReplace(outSecoes, "`n", "|")
  ;
  tamanhoListBox := 50 * tamanhoFonte
  ;
  Gui, ListarAcoes:Default
  Gui, Font, s%tamanhoFonte%, MS Sans Serif
  if (FileExist(arquivo) == "D")
    Gui, Add, Text, , Pasta: %arquivo%
  else
    Gui, Add, Text, , Arquivo: %arquivo%
  Gui, Add, Text, , A��es:
  Gui, Add, ListBox, x+m R10 Sort w%tamanhoListBox%, %outSecoes%
  Gui, Add, Button, xm R0.5 gNovaAcao, Nova A��o:
  Gui, Add, Edit, x+m
  Gui, Add, Checkbox, xm vParaTodos, V�lido para este e os pr�ximos arquivos?
  Gui, -MaximizeBox AlwaysOnTop
  Gui, ListarAcoes:Add, Button, Hidden Default gAcaoListaAcoes, Ok
  Gui, Show, AutoSize , Lista de a��es
  ;
  Pause, On
  ;
  return acaoEscolhida

ListarAcoesGuiClose:
  exitapp

NovaAcao:
  Gui, Submit, NoHide
  if (!ValidaNovaAcao())
    return
  ControlGetText, novaAcao, Edit1
  acaoEscolhida := novaAcao
  Gui, Destroy
  Pause, Off
  return

AcaoListaAcoes:
  Gui, Submit, NoHide
  ControlGetFocus, outFoco
  ; P�r para ver no caso de estar no CheckBox, vai usar oq?
  if (outFoco == "Edit1"){
    if (!ValidaNovaAcao()){
      ControlFocus, Edit1
      return
    }
    ControlGetText, acaoEscolhida, Edit1
    Gui, Destroy
    Pause, Off
  } 
  else if (outFoco == "ListBox1"){
    GuiControlGet, acaoEscolhida, , ListBox1
    if (Trim(acaoEscolhida) == "")
      return
    Gui, Destroy
    Pause, Off
  }
  else if (outFoco == "Button2"){
    GuiControlGet, acaoEscolhida, , ListBox1
    if (Trim(acaoEscolhida) <> ""){
      Gui, Destroy
      Pause, Off
    } else {
      ControlGetText, acaoEscolhida, Edit1
      if (Trim(acaoEscolhida) == ""){
        msgbox 262144, , Por favor, escolha uma a��o da lista ou digite uma nova a��o.
        ControlFocus, ListBox1
        return
      }
      ;
      if (!ValidaNovaAcao())
        return
      ;
      Gui, Destroy
      Pause, Off
    }
  }
  return
}

ValidaNovaAcao(){
  ControlGetText, novaAcao, Edit1
  if (Trim(novaAcao) == ""){
    MsgBox 262144, , N�o h� a��o preenchida. Por favor, preencha a a��o.
    return False
  }
  if (!RegExMatch(novaAcao, "^[a-zA-Z0-9]+$")){
    MsgBox 262144, , %NvAcao% � inv�lido. A��es s� podem ter letras e n�meros.
    return False
  }
  ;
  IniRead, secoes, %localIni%, %novaAcao%
  if (secoes <> ""){
    MsgBox 262144, , %novaAcao% j� existe.
    return False
  }
  return True
}