' OVE (Open-View-Edit)
' Esta � a vers�o em VBScript do script criado inicialmente em Batch Script.
' Este � o script, que atua como um 'controller', apenas acionando as a��es definidas em um arquivo .INI.
'
' Uma observa��o a se fazer, ao entender o script e os alias criados no arquivo de configura��o: os programas
' externos aqui usados est�o sendo referenciados como se os mesmos j� estivessem em alguma pasta da vari�vel 
' de ambiente PATH do Windows. Por�m, eles podem ser trocados por caminhos completos de programas, se for o caso.

' Vari�veis globais
Dim i, extensao
Dim shell, environment
Dim acao, programa
Dim alias

Set shell       = CreateObject("WScript.Shell")
Call Testar()
Call CriarAlias()

For i=1 to (WScript.Arguments.Count - 1)
  programa = WScript.Arguments(i)
  extensao = RecuperarExtensao
  
  if extensao = ".lnk" then
    AbrirAtalho
  elseif not alias.Exists(acao & extensao) then
    AcaoNaoDefinida
  else
    Dim comando
    comando = alias(acao & extensao)
    ' Eu posso inserir associa��es vazias, o que dar� a entender que n�o deve ser executado nada,
    ' ou seja, � como se estivesse "passando direto" por ele.
    if trim(len(comando)) <> 0 then
    		on error Resume Next
			  comando = Replace(comando,"###",Chr(34) & programa & Chr(34))
			  shell.Run comando
        if Err.Number <> 0 then
					Msgbox "Erro na abertura do programa." & nl() & _
                 "Verifique sua configura��o de associa��o.", _
         				 vbCritical + vbOKOnly, "Erro"
        	WScript.Quit 1
        end if
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
  if (acao <> "open") and (acao <> "view") and (acao <> "edit") then
    ErroPrograma
  end if
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
        & "Onde 'acao' deve ser: 'open', 'view' ou 'edit'"

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
    shell.Run "micro " & Chr(34) & RecuperaPathAlias(CreateObject("Scripting.FileSystemObject")) & Chr(34)
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

' Este procedimento l� as associa��es definidas no arquivo .INI,
' cujo caminho est� definido em uma fun��o separada.
Sub CriarAlias()
  Dim fso, arq
  Set fso = CreateObject("Scripting.FileSystemObject")

  if not fso.FileExists(RecuperaPathAlias(fso)) then
    MsgBox "O arquivo de configura��o de alias n�o foi encontrado.", vbCritical, "Erro"
    Set fso = Nothing
    WScript.Quit 0
  end if

  ' L� cada associa��o, e p�e em um dicion�rio, que � uma estrutura de dados do tipo chave-valor,
  ' onde a chave est� na forma "a��o.extens�o", e o valor � a a��o em si (programa e par�metros).
  Set alias = CreateObject("Scripting.Dictionary")
  Set arq = fso.OpenTextFile(RecuperaPathAlias(fso), 1)
  While not arq.AtEndOfStream
    Dim linha
    linha = arq.ReadLine
    if len(trim(linha)) <> 0 then
      if left(trim(linha),1) <> ";" then
        Dim dados
        dados = Split(linha, "=")
        alias.add trim(dados(0)), trim(dados(1))
      end if
    end if
  Wend

  arq.Close
  Set arq = Nothing
  Set fso = Nothing
End Sub

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
  RecuperaPathAlias = fso.GetParentFolderName(WScript.ScriptFullName) & "\" & "Config OVE.ini"
End Function