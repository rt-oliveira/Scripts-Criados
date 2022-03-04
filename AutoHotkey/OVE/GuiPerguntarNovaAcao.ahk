/*
	Nos casos em não há comando específico configuração para a extensão, será mostrada uma tela,
	que será perguntado se deseja criar um comando, que pode ser específico, ou até mesmo global.
*/

class GuiPerguntarNovaAcao extends CGUI{
	querCadastrar			:=	False

	__New(temAcaoGlobal, acao, extensao){
		this.Font.Font		:=	"MS Sans Serif"
		this.Font.Options	:=	"s" . OVE.tamanhoFonte
		this.DestroyOnClose	:=	True
		this.CloseOnEscape	:=	True
		this.MaximizeBox	:=	False
		this.AlwaysOnTop	:=	True
		;
		this.temAcaoGlobal	:=	temAcaoGlobal
		this.acao			:=	acao
		this.extensao		:=	extensao
		;
		this.ConstruirGui()
		;
		this.Show("")
	}
	
	ConstruirGui(){
		if (this.temAcaoGlobal){
			msg				:=	"A ação " . this.acao . " tem um comando global,`n"
			msg				.=	"mas não há um comando específico para a extensão " . this.extensao . ".`n`n"
			msg				.=	"Deseja cadastrar um comando específico para esta extensão?"
			;
			this.Title		:=	"Comando específico não definido"
		} else {
			msg				:=	"Não está definido um comando específico para a combinação " . this.acao . this.extensao . ".`n`n"
			msg				.=	"Deseja definir agora?"
			;
			this.Title		:=	"Comando não definido"
		}
		;
		this.AddControl("Text", "lblMsg", "", msg)
		this.btnSim			:=	this.AddControl("Button", "btnSim", "w650 Default", "Sim")
		this.btnNao			:=	this.AddControl("Button", "btnNao", "w650", "Não")
		this.btnNaoAcao		:=	this.AddControl("Button", "btnNaoAcao", "w650", "Não, e não pergunte novamente (para a ação " . this.acao . ")")
		this.btnNaoExt		:=	this.AddControl("Button", "btnNaoExt", "w650", "Não, e não pergunte novamente (para a extensão " . this.extensao . ")")
	}
	
	btnSim_Click(){
		this.querCadastrar	:=	True
		this.Destroy()
	}
	
	btnNao_Click(){
		this.Destroy()
	}
	
	btnNaoAcao_Click(){
		IniWrite, N, % OVE.localIni, % this.acao, permissaoCadComandoEspec*
		this.Destroy()
	}
	
	btnNaoExt_Click(){
		IniWrite, N, % OVE.localIni, % this.acao, % "permissaoCadComandoEspec" . this.extensao
		this.Destroy()
	}
}