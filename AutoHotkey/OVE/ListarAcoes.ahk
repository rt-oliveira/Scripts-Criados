; Caso 'acao' seja '-la', será aberta uma janela que lista as ações já cadastradas no
; arquivo de configurações. O usuário poderá então escolher uma das ações mostradas
; para usar no arquivo atual, ou então criar uma nova ação. 
; Haverá a opção de poder usar esta mesma ação (escolhida/criada) para todos os próximos
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
  Gui, Add, Text, , Ações:
  Gui, Add, ListBox, x+m R10 Sort w%tamanhoListBox%, %outSecoes%
  Gui, Add, Button, xm R0.5 gNovaAcao, Nova Ação:
  Gui, Add, Edit, x+m
  Gui, Add, Checkbox, xm vParaTodos, Válido para este e os próximos arquivos?
  Gui, -MaximizeBox AlwaysOnTop
  Gui, ListarAcoes:Add, Button, Hidden Default gAcaoListaAcoes, Ok
  Gui, Show, AutoSize , Lista de ações
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
  ; Pôr para ver no caso de estar no CheckBox, vai usar oq?
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
        msgbox 262144, , Por favor, escolha uma ação da lista ou digite uma nova ação.
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
    MsgBox 262144, , Não há ação preenchida. Por favor, preencha a ação.
    return False
  }
  if (!RegExMatch(novaAcao, "^[a-zA-Z0-9]+$")){
    MsgBox 262144, , %NvAcao% é inválido. Ações só podem ter letras e números.
    return False
  }
  ;
  IniRead, secoes, %localIni%, %novaAcao%
  if (secoes <> ""){
    MsgBox 262144, , %novaAcao% já existe.
    return False
  }
  return True
}