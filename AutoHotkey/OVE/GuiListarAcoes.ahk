; Caso 'acao' seja '-la', será aberta uma janela que lista as ações já cadastradas no
; arquivo de configurações. O usuário poderá então escolher uma das ações mostradas
; para usar no arquivo atual, ou então criar uma nova ação. 
; Haverá a opção de poder usar esta mesma ação (escolhida/criada) para todos os próximos
; arquivos passados.

class GuiListarAcoes extends CGUI {
	acao					:=	""
	paraTodos				:=	False
	
	__New(arquivo){
		;
		this.Font.Font		:=	"MS Sans Serif"
		this.Font.Options	:=	"s" . OVE.tamanhoFonte
		this.DestroyOnClose	:=	True
		this.Title			:=	"Lista de ações"
		this.MaximizeBox	:=	False
		this.AlwaysOnTop	:=	True
		;
		this.ConstruirGui(arquivo)
		;
		this.Show("AutoSize")
	}
	
	Escape(){
		ExitApp
	}
	
	btnNovaAcao_Click(){
		if (!this.EhNovaAcaoValida())
			return
		;
		this.acao			:=	this.AcaoDigitada()
		this.Destroy()
	}
	
	chkParaTodos_CheckedChanged(){
		this.paraTodos		:=	this.chkParaTodos.Checked
	}
	
	lstAcoes_DoubleClick(Item){
		if (this.lstAcoes.SelectedIndex){
			this.acao		:=	this.AcaoEscolhida()
			this.Destroy()
		}
	}
	
	btnOk_Click(){
		if (this.txtNovaAcao.Focused){
			if (this.EhNovaAcaoValida()){
				this.acao	:=	this.AcaoDigitada()
				this.Destroy()
			}
		}
		else if (this.lstAcoes.Focused){
			if (this.lstAcoes.SelectedIndex){
				this.acao	:=	this.AcaoEscolhida()
				this.Destroy()
			}
		}
		else if (this.btnNovaAcao.Focused){
			/*
			  Caso esteja no botão, na ordem:
				1. Vê se escolheu alguma ação no lista ações já cadastradas.
				2. Caso não tenha nenhuma ação escolhida, vê se digitou alguma nova ação.
				3. Em último caso, avisa para escolher alguma ação ou digitar uma nova ação.
			*/
			if (this.lstAcoes.SelectedIndex){
				this.acao	:=	this.AcaoEscolhida()
				this.Destroy()
			} else if (this.EhNovaAcaoValida()){
				this.acao	:=	this.AcaoDigitada()
				this.Destroy()
			} else {
				MsgBox 262144, , Por favor, escolha uma ação da lista ou digite uma nova ação.
				this.lstAcoes.Focus()
			}
		}
	}
	
	AcaoEscolhida(){
		return this.lstAcoes.SelectedItem.Text
	}
	
	AcaoDigitada(){
		return this.txtNovaAcao.Text
	}
	
	EhNovaAcaoValida(){
		novaAcao		:=	this.txtNovaAcao.Text
		;
		if (Trim(novaAcao) == ""){
			MsgBox 262144, , Não há ação preenchida. Por favor, preencha a ação.
			return False
		}
		;
		if (!RegExMatch(novaAcao, "^[a-zA-Z0-9]+$")){
			MsgBox 262144, , %novaAcao% é inválido. Ações só podem ter letras e números.
			return False
		}
		;
		if (OVE.objIniReader.ExisteSecao(novaAcao)){
			MsgBox 262144, , %novaAcao% já existe.
			return False
		}
		;
		return True
	}
	
	ConstruirGui(arquivo){
		outSecoes			:=	OVE.objIniReader.RecuperarSecoes()
		outSecoes			:=	StrReplace(outSecoes, "`n", "|")
		;
		tamanhoListBox		:=	50 * OVE.tamanhoFonte
		;
		if (FileExist(arquivo) ~= "D")
			this.AddControl("Text", "lblPastaArquivo", "", "Pasta: " . arquivo)
		else
			this.AddControl("Text", "lblPastaArquivo", "", "Arquivo: " . arquivo)
		this.AddControl("Text", "lblAcoes", "", "Ações:")
		;
		this.lstAcoes		:=	this.AddControl("ListBox", "lstAcoes", "x+m R10 Sort w" . tamanhoListBox, outSecoes)
		this.btnNovaAcao	:=	this.AddControl("Button", "btnNovaAcao", "xm R0.5", "Nova Ação:")
		this.txtNovaAcao	:=	this.AddControl("Edit", "txtNovaAcao", "x+m", "")
		this.chkParaTodos	:=	this.AddControl("Checkbox", "chkParaTodos", "xm", "Válido para este e os próximos arquivos?")
		;
		this.btnOk				:=	this.AddControl("Button", "btnOk", "Hidden Default", "Ok")
	}
	
	PostDestroy(){
		if (this.acao == "")
			ExitApp
	}
}