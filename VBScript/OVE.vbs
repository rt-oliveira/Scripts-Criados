' OVE (Open-View-Edit)
' Esta é a versão em VBScript do script criado inicialmente em Batch Script.
' Este é o script, que atua como um 'controller', apenas acionando as ações definidas em um arquivo .INI.
'
' Uma observação a se fazer, ao entender o script e os alias criados no arquivo de configuração: os programas
' externos aqui usados estão sendo referenciados como se os mesmos já estivessem em alguma pasta da variável 
' de ambiente PATH do Windows. Porém, eles podem ser trocados por caminhos completos de programas, se for o caso.

' Variáveis globais
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
    ' Eu posso inserir associações vazias, o que dará a entender que não deve ser executado nada,
    ' ou seja, é como se estivesse "passando direto" por ele.
    if trim(len(comando)) <> 0 then
    		on error Resume Next
			  comando = Replace(comando,"###",Chr(34) & programa & Chr(34))
			  shell.Run comando
        if Err.Number <> 0 then
					Msgbox "Erro na abertura do programa." & nl() & _
                 "Verifique sua configuração de associação.", _
         				 vbCritical + vbOKOnly, "Erro"
        	WScript.Quit 1
        end if
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
  if (acao <> "open") and (acao <> "view") and (acao <> "edit") then
    ErroPrograma
  end if
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
        & "Onde 'acao' deve ser: 'open', 'view' ou 'edit'"

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
    shell.Run "micro " & Chr(34) & RecuperaPathAlias(CreateObject("Scripting.FileSystemObject")) & Chr(34)
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

' Este procedimento lê as associações definidas no arquivo .INI,
' cujo caminho está definido em uma função separada.
Sub CriarAlias()
  Dim fso, arq
  Set fso = CreateObject("Scripting.FileSystemObject")

  if not fso.FileExists(RecuperaPathAlias(fso)) then
    MsgBox "O arquivo de configuração de alias não foi encontrado.", vbCritical, "Erro"
    Set fso = Nothing
    WScript.Quit 0
  end if

  ' Lê cada associação, e põe em um dicionário, que é uma estrutura de dados do tipo chave-valor,
  ' onde a chave está na forma "ação.extensão", e o valor é a ação em si (programa e parâmetros).
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
  RecuperaPathAlias = fso.GetParentFolderName(WScript.ScriptFullName) & "\" & "Config OVE.ini"
End Function