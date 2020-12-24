' OVE (Open-View-Edit)
' Esta é a versão em VBScript do script criado inicialmente em Batch Script.
' Este é o script, que atua como um 'controller', apenas acionando as ações definidas em um arquivo .INI.
'
' Uma observação a se fazer, ao entender o script e os alias criados no arquivo de configuração: os programas
' externos aqui usados estão sendo referenciados como se os mesmos já estivessem em alguma pasta da variável 
' de ambiente PATH do Windows. Porém, eles podem ser trocados por caminhos completos de programas, se for o caso.

' Variáveis globais
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
      ' Eu posso inserir associações vazias, o que dará a entender que não deve ser executado nada,
      ' ou seja, é como se estivesse "passando direto" por ele.
      if trim(len(comando)) <> 0 then
        on error Resume Next
    		comando = Replace(comando,"###",Chr(34) & programa & Chr(34))
    		shell.Run comando
        if Err.Number <> 0 then
			   Msgbox "Erro na abertura do programa." & nl() & _
                 "Verifique sua configuração de associação." & nl() & nl() & _
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

'-------------------- Funções e Procedimentos
Sub Testar()
  ' Tem, no mínimo, 2 argumentos?
  if WScript.Arguments.Count < 2 then
    ErroPrograma
  end if

  acao = lcase(WScript.Arguments(0))

  ' É uma ação válida?
  ' As ações só podem conter letras (maiúsculas ou minúsculas, mas sem acentos) e números
  ' Outros caracteres são inválidos para a ação.
  Set Reg = new RegExp
  Reg.Pattern = "^[a-zA-Z0-9]+$"
  if not Reg.test(acao) then
    ErroPrograma
  end if
  Set Reg = Nothing
End Sub

' Informa que, pelo menos, 1 arquivo e 1 ação, devem ser informados para o programa.
Sub ErroPrograma()
  Dim msg
  msg = "Não foi passada ação ou arquivo para o programa." & nl _
        & nl _
        & "O programa deve ser usado na seguinte forma:" _
        & nl _
        & "OVE acao programa1 [programa2 programa3 ...]" _
        & nl _
        & "Onde 'acao' deve ser um termo que contenha somente letras (sem acentos) e números."

  MsgBox msg,vbOKOnly,"Erro"
  WScript.Quit 1
End Sub

Sub AcaoNaoDefinida()
  msg = "A acao '" & acao & extensao & "' não foi definida." & nl _
        & "Deseja definir agora?"

  Dim resposta
  resposta = MsgBox(msg, vbYesNo, "Ação não definida")
  ' Caso não exista a associação, eu dou a opção de criar a associação, para depois usá-lo.
  if resposta = vbYes then
    shell.Run "ove edit " & Chr(34) & RecuperaPathAlias(CreateObject("Scripting.FileSystemObject")) & Chr(34)
    WScript.Quit 1
  end if
end Sub

' Na versão em Batch Script do mesmo, o OVE aceitava, para casos de atalhos (arquivos .LNK), apenas
' a ação de abrir ('open'). Porém, para o VBScript foi feita uma atualização, na qual permite qualquer ação para
' esta extensão.
Sub AbrirAtalho()
    Dim atalho, destino
    Dim objFso
    Set objFso = CreateObject("Scripting.FileSystemObject")
    Set atalho = shell.Createshortcut(programa)
    destino = atalho.TargetPath
    ' Com este teste adicionado, agora é possível mandar para este script atalhos que contenham argumentos próprios.
    ' Neste tipo de caso, o que ocorre é que geralmente está se tratando de um programa que contém argumentos em seu atalho.
    ' Sendo assim, se houver argumentos o atalho, apenas executa o programa do atalho, passando o argumento lido para o mesmo.
    if trim(atalho.Arguments) <> "" then  ' Se for um atalho com argumentos
      if objFso.FileExists(destino) then
        shell.Run Chr(34) & destino & Chr(34) & " " & TratarArgumento(trim(atalho.Arguments))
      end if
    else
      ' Já aqui é o mesmo teste de 'arquivo ou diretório' que já havia antes.
      ' Se for arquivo, apenas para o destino do atalho para este script.
      ' Se for diretório, abre um explorador de arquivos para esta pasta.
      if objFso.FileExists(destino) then      ' é arquivo
        shell.Run "ove " & acao & " " & Chr(34) & destino & Chr(34)
      else                                    ' é diretório
        shell.Run "doublecmd -C -T -path " & Chr(34) & destino & Chr(34)
      end if
    end if
    Set objFso = Nothing
End sub 

' Esta função foi criada para pôr os argumentos entre aspas, pois podem haver argumentos
' (seja programa, seja arquivo) que esteja em um caminho que contenha espaço em branco. 
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

' Foi feita uma atualização para a versão 1.0.0 em VBScript desse script:
' na versão anterior era lido todo o arquivo de configuração, e as associações
' eram colocadas em um dicionário que existia durante toda a execução do script.
'
' Agora, isso foi substituído por uma função que chama um programa (que está neste repositório)
' que percorre todo o arquivo .ini, para recuperar o comando que deve ser executado para aquela
' ação e extensão.
Function RecuperarAssociacao(acao,extensao)
  Dim fso, pathAlias, objShellIni
  Set fso = CreateObject("Scripting.FileSystemObject")
  pathAlias = RecuperaPathAlias(fso)
  
  Set objShellIni = shell.Exec("cmd /c leini """ + pathAlias + """ " + acao + " """ + acao + extensao + """")
  Do While objShellIni.Status = 0
  	WScript.Sleep 250
  Loop

  ' O programa 'leini' pode trazer 3 tipos de retorno:
  ' - Código 5: Não foi encontrado o arquivo .ini.
  ' - Código 1: Não achou a chave na seção informada neste arquivo .ini.
  ' - Código 0: Achou a chave na seção informada, e imprimiu o valor respectivo.
  If objShellIni.ExitCode = 5 Then
  	MsgBox "O arquivo de configuração de alias não foi encontrado.", vbCritical, "Erro"
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

' Recupera a extensão do arquivo que está sendo tratado no momento.
Function RecuperarExtensao()
  Dim indiceext
  indiceext = InStrRev(programa,".")
  If indiceext = 0 then
    RecuperarExtensao = Mid(programa,InstrRev(programa, "\"))
  else
    RecuperarExtensao = lcase(Mid(programa, indiceext))
  end if
End function

' Outras funções
Function nl()
  nl = Chr(10)
End Function

' É aqui que fica definido o caminho do arquivo de configuração .INI. Por enquanto, ele fica na mesma pasta
' do script, com o nome "Config OVE.ini", mas pode ser trocado para um outro caminho.
Function RecuperaPathAlias(fso)
  Dim caminho
  caminho = fso.GetParentFolderName(WScript.ScriptFullName)
  if right(caminho,1) <> "\" then
    caminho = caminho & "\"
  end if
  RecuperaPathAlias = caminho & "Config OVE.ini"
End Function