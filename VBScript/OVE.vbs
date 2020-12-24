' OVE (Open-View-Edit)
' Esta � a vers�o em VBScript do script criado inicialmente em Batch Script.
' Este � o script, que atua como um 'controller', apenas acionando as a��es definidas em um arquivo .INI.
'
' Uma observa��o a se fazer, ao entender o script e os alias criados no arquivo de configura��o: os programas
' externos aqui usados est�o sendo referenciados como se os mesmos j� estivessem em alguma pasta da vari�vel 
' de ambiente PATH do Windows. Por�m, eles podem ser trocados por caminhos completos de programas, se for o caso.

' Vari�veis globais
Dim i, extensao
Dim shell, comando
Dim acao, programa
Dim achou

Set shell       = CreateObject("WScript.Shell")
Call Testar()

For i=1 to (WScript.Arguments.Count - 1)
  programa = WScript.Arguments(i)
  extensao = RecuperarExtensao
  
  if extensao = ".lnk" then
    AbrirAtalho
  else
    comando = RecuperarAssociacao(acao, extensao)
    if achou then
      ' Eu posso inserir associa��es vazias, o que dar� a entender que n�o deve ser executado nada,
      ' ou seja, � como se estivesse "passando direto" por ele.
      if trim(len(comando)) <> 0 then
        on error Resume Next
    		comando = Replace(comando,"###",Chr(34) & programa & Chr(34))
    		shell.Run comando
        if Err.Number <> 0 then
			   Msgbox "Erro na abertura do programa." & nl() & _
                 "Verifique sua configura��o de associa��o." & nl() & nl() & _
                 "Comando: " & comando, _
         		vbCritical + vbOKOnly, "Erro"
        	WScript.Quit 1
        end if
      end if
    else
      AcaoNaoDefinida
    end if
  end if
next

'-------------------- Fun��es e Procedimentos
Sub Testar()
  ' Tem, no m�nimo, 2 argumentos?
  if WScript.Arguments.Count < 2 then
    ErroPrograma
  end if

  acao = lcase(WScript.Arguments(0))

  ' � uma a��o v�lida?
  ' As a��es s� podem conter letras (mai�sculas ou min�sculas, mas sem acentos) e n�meros
  ' Outros caracteres s�o inv�lidos para a a��o.
  Set Reg = new RegExp
  Reg.Pattern = "^[a-zA-Z0-9]+$"
  if not Reg.test(acao) then
    ErroPrograma
  end if
  Set Reg = Nothing
End Sub

' Informa que, pelo menos, 1 arquivo e 1 a��o, devem ser informados para o programa.
Sub ErroPrograma()
  Dim msg
  msg = "N�o foi passada a��o ou arquivo para o programa." & nl _
        & nl _
        & "O programa deve ser usado na seguinte forma:" _
        & nl _
        & "OVE acao programa1 [programa2 programa3 ...]" _
        & nl _
        & "Onde 'acao' deve ser um termo que contenha somente letras (sem acentos) e n�meros."

  MsgBox msg,vbOKOnly,"Erro"
  WScript.Quit 1
End Sub

Sub AcaoNaoDefinida()
  msg = "A acao '" & acao & extensao & "' n�o foi definida." & nl _
        & "Deseja definir agora?"

  Dim resposta
  resposta = MsgBox(msg, vbYesNo, "A��o n�o definida")
  ' Caso n�o exista a associa��o, eu dou a op��o de criar a associa��o, para depois us�-lo.
  if resposta = vbYes then
    shell.Run "ove edit " & Chr(34) & RecuperaPathAlias(CreateObject("Scripting.FileSystemObject")) & Chr(34)
    WScript.Quit 1
  end if
end Sub

' Na vers�o em Batch Script do mesmo, o OVE aceitava, para casos de atalhos (arquivos .LNK), apenas
' a a��o de abrir ('open'). Por�m, para o VBScript foi feita uma atualiza��o, na qual permite qualquer a��o para
' esta extens�o.
Sub AbrirAtalho()
    Dim atalho, destino
    Dim objFso
    Set objFso = CreateObject("Scripting.FileSystemObject")
    Set atalho = shell.Createshortcut(programa)
    destino = atalho.TargetPath
    ' Com este teste adicionado, agora � poss�vel mandar para este script atalhos que contenham argumentos pr�prios.
    ' Neste tipo de caso, o que ocorre � que geralmente est� se tratando de um programa que cont�m argumentos em seu atalho.
    ' Sendo assim, se houver argumentos o atalho, apenas executa o programa do atalho, passando o argumento lido para o mesmo.
    if trim(atalho.Arguments) <> "" then  ' Se for um atalho com argumentos
      if objFso.FileExists(destino) then
        shell.Run Chr(34) & destino & Chr(34) & " " & TratarArgumento(trim(atalho.Arguments))
      end if
    else
      ' J� aqui � o mesmo teste de 'arquivo ou diret�rio' que j� havia antes.
      ' Se for arquivo, apenas para o destino do atalho para este script.
      ' Se for diret�rio, abre um explorador de arquivos para esta pasta.
      if objFso.FileExists(destino) then      ' � arquivo
        shell.Run "ove " & acao & " " & Chr(34) & destino & Chr(34)
      else                                    ' � diret�rio
        shell.Run "doublecmd -C -T -path " & Chr(34) & destino & Chr(34)
      end if
    end if
    Set objFso = Nothing
End sub 

' Esta fun��o foi criada para p�r os argumentos entre aspas, pois podem haver argumentos
' (seja programa, seja arquivo) que esteja em um caminho que contenha espa�o em branco. 
' Para tratar isso, no Windows o caminho deve estar contido entre aspas.
Function TratarArgumento(byval argumento)
  Dim argTratado
  argTratado = argumento
  if left(argTratado,1) <> Chr(34) then
    argTratado = Chr(34) & argTratado
  end if
  if right(argTratado,1) <> Chr(34) then
    argTratado = argTratado & Chr(34)
  end if
  TratarArgumento = argTratado
End function

' Foi feita uma atualiza��o para a vers�o 1.0.0 em VBScript desse script:
' na vers�o anterior era lido todo o arquivo de configura��o, e as associa��es
' eram colocadas em um dicion�rio que existia durante toda a execu��o do script.
'
' Agora, isso foi substitu�do por uma fun��o que chama um programa (que est� neste reposit�rio)
' que percorre todo o arquivo .ini, para recuperar o comando que deve ser executado para aquela
' a��o e extens�o.
Function RecuperarAssociacao(acao,extensao)
  Dim fso, pathAlias, objShellIni
  Set fso = CreateObject("Scripting.FileSystemObject")
  pathAlias = RecuperaPathAlias(fso)
  
  Set objShellIni = shell.Exec("cmd /c leini """ + pathAlias + """ " + acao + " """ + acao + extensao + """")
  Do While objShellIni.Status = 0
  	WScript.Sleep 250
  Loop

  ' O programa 'leini' pode trazer 3 tipos de retorno:
  ' - C�digo 5: N�o foi encontrado o arquivo .ini.
  ' - C�digo 1: N�o achou a chave na se��o informada neste arquivo .ini.
  ' - C�digo 0: Achou a chave na se��o informada, e imprimiu o valor respectivo.
  If objShellIni.ExitCode = 5 Then
  	MsgBox "O arquivo de configura��o de alias n�o foi encontrado.", vbCritical, "Erro"
  	Set fso = Nothing
  	WScript.Quit 0
  ElseIf objShellIni.ExitCode = 1 Then
  	achou = False
  	RecuperarAssociacao = ""
  ElseIf objShellIni.ExitCode = 0 Then
  	RecuperarAssociacao = Trim(replace(objShellIni.StdOut.ReadAll,vbcrlf, ""))
  	achou = True
  End If
End Function

' Recupera a extens�o do arquivo que est� sendo tratado no momento.
Function RecuperarExtensao()
  Dim indiceext
  indiceext = InStrRev(programa,".")
  If indiceext = 0 then
    RecuperarExtensao = Mid(programa,InstrRev(programa, "\"))
  else
    RecuperarExtensao = lcase(Mid(programa, indiceext))
  end if
End function

' Outras fun��es
Function nl()
  nl = Chr(10)
End Function

' � aqui que fica definido o caminho do arquivo de configura��o .INI. Por enquanto, ele fica na mesma pasta
' do script, com o nome "Config OVE.ini", mas pode ser trocado para um outro caminho.
Function RecuperaPathAlias(fso)
  Dim caminho
  caminho = fso.GetParentFolderName(WScript.ScriptFullName)
  if right(caminho,1) <> "\" then
    caminho = caminho & "\"
  end if
  RecuperaPathAlias = caminho & "Config OVE.ini"
End Function