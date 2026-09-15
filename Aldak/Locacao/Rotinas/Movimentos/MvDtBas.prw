#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} MVDTBAS
Alteração da Data Base (ZI_DTBASE) dos itens do movimento de locação.

@author Ewerton Alex Vicentin
@since 08/09/2026
@version P12
/*/
User Function MVDTBAS()

Local cAdmins  := AllTrim(GetMv("LC_USERADM"))
Local cUsuario := __cUserId

If Empty(cAdmins) .or. !(cUsuario $ cAdmins)
	Help(,, "SEMPERM",, "Usuário sem permissão para alterar a Data Base. Cadastre o usuário no parâmetro LC_USERADM.", 1, 0)
	Return
EndIf

FWExecView("Alteração da Data Base", "MVDTBAS", MODEL_OPERATION_UPDATE, /*oDlg*/, {|| .T.})

Return

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC de alteração da Data Base.

@author Ewerton Alex Vicentin
@since 08/09/2026
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruSZH := FWFormStruct(1, "SZH")
Local oStruSZI := FWFormStruct(1, "SZI")
Local nX       := 0
Local aCampos  := {}

// Bloqueia a edição de todos os campos do cabeçalho.
aCampos := oStruSZH:GetFields()
For nX := 1 to Len(aCampos)
	oStruSZH:SetProperty(aCampos[nX][3], MODEL_FIELD_WHEN, {|| .F.})
Next nX

// Bloqueia a edição de todos os campos dos itens, liberando somente a Data Base.
aCampos := oStruSZI:GetFields()
For nX := 1 to Len(aCampos)
	If AllTrim(aCampos[nX][3]) == "ZI_DTBASE"
		oStruSZI:SetProperty(aCampos[nX][3], MODEL_FIELD_WHEN, {|| .T.})
	Else
		oStruSZI:SetProperty(aCampos[nX][3], MODEL_FIELD_WHEN, {|| .F.})
	EndIf
Next nX

oModel := MPFormModel():New("MVDTBASM", /*bPreValidacao*/, /*bPosValidacao*/, {|oMdl| GrvDtBase(oMdl)}, /*bCancel*/)

oModel:AddFields("SZHMASTER",, oStruSZH)

oModel:AddGrid("SZIDETAIL", "SZHMASTER", oStruSZI)

oModel:SetRelation("SZIDETAIL", {{"ZI_FILIAL", "xFilial('SZI')"}, {"ZI_CODPOST", "ZH_CODPOST"}, {"ZI_LOCALID", "ZH_LOCALID"},;
    {"ZI_DOC", "ZH_DOC"}}, SZI->(IndexKey(1)))

oModel:GetModel("SZIDETAIL"):SetNoInsertLine(.T.)
oModel:GetModel("SZIDETAIL"):SetNoDeleteLine(.T.)

oModel:SetPrimaryKey({})

oModel:SetDescription("Alteração da Data Base")
oModel:GetModel("SZHMASTER"):SetDescription("Dados do Movimento")
oModel:GetModel("SZIDETAIL"):SetDescription("Dados dos Itens dos Movimentos")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC de alteração da Data Base.

@author Ewerton Alex Vicentin
@since 08/09/2026
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZH   := FWFormStruct(2, "SZH", {|cCampo| AllTrim(cCampo)+"|"$ "ZH_DOC|ZH_EMISSAO|ZH_CODPOST|ZH_DESCPOS|ZH_LOCALID|ZH_DESCLOC|"+;
                                                                          "ZH_CC|ZH_DESCCC|ZH_CODRESP|ZH_DESCRES|ZH_CHAMADO|ZH_MOTIVO|ZH_STATUS|ZH_DPSCM|"})
Local oStruSZI   := FWFormStruct(2, "SZI", {|cCampo| !AllTrim(cCampo)+"|"$ "ZI_CODPOST|ZI_LOCALID|ZI_DOC|ZI_DATADEV|ZI_PERDA|ZI_DPSMI|ZI_DPSEQ|ZI_DPSKIT|"+;
                                                                            "ZI_DPSSUB|ZI_DPSMC|ZI_DPSEQDV|ZI_DPSMG|"})
Local oModel     := FWLoadModel("MVDTBAS")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZH", oStruSZH, "SZHMASTER")
oView:AddGrid("VIEW_SZI", oStruSZI, "SZIDETAIL")

oView:CreateHorizontalBox("CABEC", 35)
oView:CreateHorizontalBox("GRID", 65)

oView:SetOwnerView("VIEW_SZH", "CABEC")
oView:SetOwnerView("VIEW_SZI", "GRID")

oView:SetCloseOnOk({|| .T.})

Return(oView)

/*/{Protheus.doc} GrvDtBase
Gravação da alteração da Data Base.

@author Ewerton Alex Vicentin
@since 08/09/2026
@version P12
/*/
Static Function GrvDtBase(oModel)

Local nX         := 0
Local cLogMdl    := ""
Local oModelSZI  := oModel:GetModel("SZIDETAIL")
Local nLinhas    := oModelSZI:Length()
Local aSaveLines := FWSaveRows()
Local lRetorno   := .T.

For nX := 1 to nLinhas
	oModelSZI:GoLine(nX)

	If !oModelSZI:IsDeleted()
		If Empty(oModelSZI:GetValue("ZI_DTBASE"))
			Help(,, "DTBVAZIA",, "[Item: " + AllTrim(cValToChar(oModelSZI:GetValue("ZI_ITEM"))) + "] Preencha a Data Base.", 1, 0)
			FWRestRows(aSaveLines)
			Return(.F.)
		EndIf
	EndIf
Next nX

FWRestRows(aSaveLines)

Begin Sequence
	If !(lRetorno := FWFormCommit(oModel))
		cLogMdl := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
		cLogMdl += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
		cLogMdl += cValToChar(oModel:GetErrorMessage()[6])
		Help( ,,"U_MOVDTBASE",,cLogMdl, 1, 0 )
		Break
	EndIf
End Sequence

Return(lRetorno)
