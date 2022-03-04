/*
	Querendo criar comando, abre-se uma nova tela, perguntando qual o
	comando que deseja configurar.
	
	Pode configurar tanto um comando global (em casos de não existência),
	como comandos específicos (quando há o primeiro, mas não há o último).
*/

class GuiNovaAcao extends CGUI {
	lstOpcoes					:=	""
	chkAcaoGlobal				:=	""
	temComandos					:=	False
	novaAcao					:=	""
	
	__New(arquivo, extensao, acao, temAcaoGlobal){
		this.Font.Font			:=	"MS Sans Serif"
		this.Font.Options		:=	"s" . OVE.tamanhoFonte
		this.Title				:=	"Cadastro de comando"
		this.DestroyOnClose		:=	True
		this.CloseOnEscape		:=	True
		;
		this.acao				:=	acao
		this.extensao			:=	extensao
		;
		this.ConstruirGui(arquivo, extensao, acao, temAcaoGlobal)
		;
		this.Show("AutoSize")
	}
	
	ConstruirGui(arquivo, extensao, acao, temAcaoGlobal){
		if (FileExist(arquivo) ~= "D")
			this.AddControl("Text", "lblPastaArquivo", "", "Pasta: " . arquivo)
		else
			this.AddControl("Text", "lblPastaArquivo", "", "Arquivo: " . arquivo)
		;
		comandosSecao			:=	OVE.objIniReader.RecuperarSecao(acao)
		Loop, Parse, comandosSecao, `n
		{
			commArr		:=	StrSplit(A_LoopField, "=", , 2)
			if (commArr[1] ~= "^(\.|\*|\\|\:)"){
				if (!temComandos){
					this.AddControl("Text", "lblCopiar", "", "Copiar associação de:")
					this.lstOpcoes		:=	this.AddControl("ListView", "lstOpcoes", "-WantF2 Grid w800 NoSortHdr Sort r10 x+m", "Associação|Comando")
					temComandos			:=	!temComandos
				}
				this.lstOpcoes.Items.Add("", commArr[1], commArr[2])
			}
		}
		this.lstOpcoes.ModifyCol(1, "AutoHdr")
		this.btnNovoComando		:=	this.AddControl("Button", "btnNovoComando", "xm R0.5", "Comando:")
		this.txtNovoComando		:=	this.AddControl("Edit", "txtNovoComando", "x+m w850", "")
		if (!IsObject(this.lstOpcoes))
			this.txtNovoComando.Focus()
		if (!temAcaoGlobal)
			this.chkAcaoGlobal	:=	this.AddControl("Checkbox", "chkAcaoGlobal", "xm", "Comando global da ação " . acao)
		this.AddControl("Text", "lblAjuda", "xm", "Dica: a máscara ### pode ser usada. Ela será substituída pelo caminho do arquivo/pasta.")
		;
		this.btnOk				:=	this.AddControl("Button", "btnOk", "Hidden Default", "Ok")
	}
	
	btnNovoComando_Click(){
		if (this.EhNovoComandoValido()){
			this.NovoComando(this.ComandoDigitado())
			this.Destroy()
		}
	}
	
	btnOk_Click(){
		if (this.lstOpcoes.Focused){
			if (this.lstOpcoes.SelectedIndex){
				this.NovoComando(this.ComandoEscolhido())
				this.Destroy()
			}
		}
		else if (this.txtNovoComando.Focused){
			if (this.EhNovoComandoValido()){
				this.NovoComando(this.ComandoDigitado())
				this.Destroy()
			}
		}
		else if (this.btnNovoComando.Focused){
			if (this.lstOpcoes.SelectedIndex){
				this.NovoComando(this.ComandoEscolhido())
				this.Destroy()
			}
			else if (this.EhNovoComandoValido()){
				this.NovoComando(this.ComandoDigitado())
				this.Destroy()
			}
		}
	}
	
	EhNovoComandoValido(){
		comandoDigitado		:=	this.ComandoDigitado()
		;
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
	
	lstOpcoes_DoubleClick(){
		if (this.lstOpcoes.SelectedIndex){
			this.NovoComando(this.ComandoEscolhido())
			this.Destroy()
		}
	}
	
	NovoComando(comando){
		tmpComando		:=	comando
		;
		if (this.chkAcaoGlobal.Checked)
			OVE.objIniReader.EscreverChaveValor(this.acao, "*", tmpComando)
		else
			OVE.objIniReader.EscreverChaveValor(this.acao, this.extensao, tmpComando)
		;
		this.novaAcao	:=	tmpComando
	}
	
	ComandoDigitado(){
		return this.txtNovoComando.Text
	}
	
	ComandoEscolhido(){
		return this.lstOpcoes.Items[this.lstOpcoes.SelectedIndex][2]
	}
}