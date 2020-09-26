global acao
global localIni
Testar()

localIni = %A_ScriptDir%\Config OVE.ini
shell := ComObjCreate("WScript.Shell")
shell.CurrentDirectory := A_ScriptDir

for i, arquivo in A_Args
{
  if (i = 1)
    continue
  else
  {
    SplitPath, arquivo, nomeArquivo, , extensao
    StringLower, extensao, extensao
    ;
    if (extensao = "lnk")
      TratarAtalho(arquivo)
    else {
      extensao := (extensao = "") ? "\"nomeArquivo : "."extensao
      IniRead, comando, %localIni%, %acao%, %acao%%extensao%
      comando = %comando% ; Para remover espa�os em branco no in�cio e no fim da string
      if (comando = "ERROR")
        AcaoNaoDefinida(extensao)
      else if (comando <> "")
        ExecutarComando(comando, arquivo)
    }
  }
}

;----------------------------------------------------------------
Testar(){
  ; Tem, no m�nimo, 2 argumentos
  if (A_Args.Length() < 2)
    ErroOVE()
  ;
  ; � uma a��o v�lida?
  acao := A_Args[1]
  if (!RegExMatch(acao, "^[a-zA-Z0-9]+$"))
    ErroOVE()
}

ErroOVE(){
  msg = 
  (
    N�o foi passada a��o ou arquivo para o programa.

O programa deve ser usado da seguinte forma:
OVE acao programa1 [programa2 programa3 ...]

Onde 'acao' deve ser um termo que contenha somente letras (sem acentos) e n�meros.
  )
  MsgBox, , OVE, %msg%
  exitapp
}

TratarAtalho(arquivo){
  local comandoAtalho
  FileGetShortcut, %arquivo%, destino, , argumentos
  if (Trim(argumentos) <> "")
  {
    if (FileExist(destino))
      Run, "%destino%" %argumentos%
  } else {
    tipo := FileExist(destino)
    if (tipo = "D")     ; � diret�rio
    {
      IniRead, comandoAtalho, %localIni%, open, openPastas
      comandoAtalho = %comandoAtalho%
      if (comandoAtalho = "ERROR")
        AcaoNaoDefinida("Pastas")
      else
        ExecutarComando(comandoAtalho, destino)
    } else                ; � arquivo
    {
      comandoAtalho := A_IsCompiled ? """" A_ScriptFullPath """ " acao " ###" : """" A_AhkPath """" " """ A_ScriptFullPath """ " acao " ###"
      ExecutarComando(comandoAtalho, destino)
    }
  }
}

AcaoNaoDefinida(extensao){
  msgbox, 4, ,
  (
  A a��o %acao%%extensao% n�o foi definida.
Deseja definir agora?
  )
  IfMsgBox, Yes
  {
    while (1=1){
      InputBox, comandoASerFeito, A��o n�o definida, Digite o comando para a a��o %acao%%extensao%
      comandoASerFeito = %comandoASerFeito%
      if (comandoASerFeito = ""){
        MsgBox, 4, , Confirma a inclus�o de comando vazio para a a��o %acao%%extensao%?
        ifMsgBox, Yes
        {
          IniWrite, %comandoASerFeito%, %localIni%, %acao%, %acao%%extensao%
          return
        }
      } else {
        If (!InStr(comandoASerFeito, "###")){
          msgbox, Em comandos n�o-vazios, a m�scara ### deve existir.
        } else {
          IniWrite, %comandoASerFeito%, %localIni%, %acao%, %acao%%extensao%
          return
        }
      }
    }
  }
}

ExecutarComando(comando, arquivo){
  global shell
  try {
    comando := StrReplace(comando, "###", """" arquivo """")
    shell.Run(comando)
  } catch {
    msgbox, 
    (
    Erro na abertura do programa.
          
Verifique sua configura��o de associa��o.
Comando: %comando%
    )
    exitapp
  }
}