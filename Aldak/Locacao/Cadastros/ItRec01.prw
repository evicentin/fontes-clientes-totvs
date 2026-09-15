#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} ITREC01
Cadastro de Centros de Custos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function ITREC01()

Local oBrowse
Local cFilter := U_MBLocxUsr(1, "SZN")

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("SZN")
oBrowse:SetDescription("Itens Recorrentes - Rateio")

oBrowse:SetFilterDefault(If(Empty(cFilter), "ZN_TIPO == 'R'", " .and. ZN_TIPO == 'R'"))

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opções do Cadastro

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MenuDef()

Local aRotina := FWMVCMenu("ITREC01")

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oStruSZN := FWFormStruct(1, "SZN")
Local oStruSZE := FWFormStruct(1, "SZE")
Local oStruSZO := FWFormStruct(1, "SZO")
Local oStruSZS := FWFormStruct(1, "SZS")

Local oModel := MPFormModel():New("ITREC01M", /*bPreValidacao*/, {|oModel| TudoOk(oModel)}, /*bConfirm*/, /*bCancel*/ )

oStruSZN:SetProperty('ZN_TIPO', MODEL_FIELD_INIT , {|| 'R'})

oStruSZN:SetProperty('ZN_CODPOST', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "U_VlCdPost()"))
oStruSZN:SetProperty('ZN_NUMQQP', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "U_VlNumQQP()"))

oStruSZE:SetProperty('ZE_ITEM', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "U_VlItQQP()"))

oStruSZO:SetProperty('ZO_CC', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "U_VldCC()"))

oStruSZS:SetProperty('ZS_LOCALID', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "U_VldLoc()"))

oModel:AddFields("SZNMASTER",, oStruSZN)

oModel:AddGrid("SZEDETAIL", "SZNMASTER", oStruSZE,, {|oModelGrid| SZELinOk(oModelGrid)})
oModel:AddGrid("SZODETAIL", "SZEDETAIL", oStruSZO,, {|oModelGrid| SZOLinOk(oModelGrid)})
oModel:AddGrid("SZSDETAIL", "SZEDETAIL", oStruSZS,, {|oModelGrid| SZSLinOk(oModelGrid)})

oModel:SetRelation("SZEDETAIL", {{"ZE_FILIAL", "xFilial('SZE')"}, {"ZE_CODIGO", "ZN_CODIGO"}}, SZE->(IndexKey(1)))
oModel:SetRelation("SZODETAIL", {{"ZO_FILIAL", "xFilial('SZO')"}, {"ZO_CODIGO", "ZN_CODIGO"}, {"ZO_ITEM", "ZE_ITREC"}}, SZO->(IndexKey(1)))
oModel:SetRelation("SZSDETAIL", {{"ZS_FILIAL", "xFilial('SZS')"}, {"ZS_CODIGO", "ZN_CODIGO"}, {"ZS_ITEM", "ZE_ITREC"}}, SZS->(IndexKey(1)))

oModel:SetPrimaryKey({})

oModel:SetDescription("Itens Recorrentes")

oModel:GetModel("SZNMASTER"):SetDescription("Dados Itens Rateio")
oModel:GetModel("SZEDETAIL"):SetDescription("Dados Itens QQP")
oModel:GetModel("SZODETAIL"):SetDescription("Dados Centros de Custos")
oModel:GetModel("SZSDETAIL"):SetDescription("Dados Localidades")

oModel:GetModel("SZODETAIL"):SetUniqueLine( {"ZO_CC"})
oModel:GetModel("SZSDETAIL"):SetUniqueLine( {"ZS_LOCALID"})

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZN := FWFormStruct(2, "SZN", {|cCampo| !AllTrim(cCampo)+"|"$ "ZE_LOG|"})
Local oStruSZE := FWFormStruct(2, "SZE", {|cCampo| AllTrim( cCampo )+"|"$ "ZE_ITREC|ZE_ITEM|ZE_DESCRI|ZE_QUANT|ZE_STATUS|ZE_DATAINI|ZE_DATAFIM|"})
Local oStruSZO := FWFormStruct(2, "SZO", {|cCampo| AllTrim( cCampo )+"|"$ "ZO_CC|ZO_DESCCC|ZO_PERC|"})
Local oStruSZS := FWFormStruct(2, "SZS", {|cCampo| AllTrim( cCampo )+"|"$ "ZS_LOCALID|ZS_DESCLOC|"})

Local oModel   := FWLoadModel("ITREC01")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZN", oStruSZN, "SZNMASTER")
oView:AddGrid("VIEW_SZE", oStruSZE, "SZEDETAIL")
oView:AddGrid("VIEW_SZO", oStruSZO, "SZODETAIL")
oView:AddGrid("VIEW_SZS", oStruSZS, "SZSDETAIL")

oView:AddIncrementField('VIEW_SZE', 'ZE_ITREC')

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("GRID", 40)
oView:CreateHorizontalBox("DET", 30)

oView:CreateVerticalBox('RODAPEESQ', 60, 'DET')
oView:CreateVerticalBox('RODAPEDIR', 40, 'DET')

oView:SetOwnerView("VIEW_SZN", "CABEC")
oView:SetOwnerView("VIEW_SZE", "GRID")
oView:SetOwnerView("VIEW_SZO", "RODAPEESQ")
oView:SetOwnerView("VIEW_SZS", "RODAPEDIR")

Return(oview)

/*/{Protheus.doc} VlCdPost
Gatilhos do campo código do posto (ZN_CODPOST).

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function VlCdPost()

Local oModel    := FWModelActive()
Local oModelSZN := oModel:GetModel("SZNMASTER")
Local cCodPosto := oModelSZN:GetValue("ZN_CODPOST")

SZ1->(DbSetOrder(1)) //Cód.Posto

If !Empty(cCodPosto)
    If !SZ1->(DbSeek(xFilial("SZ1") + cCodPosto))
        Return .F.
    EndIf
EndIf

oModelSZN:LoadValue("ZN_DESCPOS", SZ1->Z1_DESCRI)
oModelSZN:LoadValue("ZN_PROJETO", AllTrim(SZ1->Z1_PROJET))

Return(.T.)

/*/{Protheus.doc} VlNumQQP
Valida o campo  Num. QQP (ZN_NUMQQP).

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function VlNumQQP()

Local oModel    := FWModelActive()
Local oModelSZN := oModel:GetModel("SZNMASTER")
Local cProjeto  := oModelSZN:GetValue("ZN_PROJETO")
Local cNumQQP   := oModelSZN:GetValue("ZN_NUMQQP")

Z43->(DbSetOrder(1)) //Projeto + Num.QQP

If !Empty(cProjeto)
    If !Z43->(DbSeek(xFilial("Z43") + cProjeto + cNumQQP))
        Return .F.
    EndIf
EndIf

Return(.T.)

/*/{Protheus.doc} VlItQQP
Valida o campo  Num. QQP (ZN_NUMQQP).

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function VlItQQP()

Local oModel    := FWModelActive()
Local oModelSZN := oModel:GetModel("SZNMASTER")
Local oGrid     := oModel:GetModel("SZEDETAIL")
Local cProjeto  := oModelSZN:GetValue("ZN_PROJETO")
Local cNumQQP   := oModelSZN:GetValue("ZN_NUMQQP")
Local nLinha    := oGrid:GetLine()
Local cItem     := oGrid:GetValue("ZE_ITEM", nLinha, oModel)

Z42->(DbSetOrder(3)) // Item QQP + Projeto + Num. do QQP

If !Empty(cItem)
    If !Z42->(DbSeek(xFilial("Z42") + cItem + cProjeto + cNumQQP))
        Return .F.
    EndIf
EndIf

oGrid:SetValue("ZE_DESCRI", Z42->Z42_DESC)

Return(.T.)

/*/{Protheus.doc} VldCC
Valida o campo  Num. QQP (ZN_NUMQQP).

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function VldCC()

Local oModel    := FWModelActive()
Local oModelSZN := oModel:GetModel("SZNMASTER")
Local oGrid     := oModel:GetModel("SZODETAIL")
Local cCodPosto := oModelSZN:GetValue("ZN_CODPOST")
Local nLinha    := oGrid:GetLine()
Local cCC       := oGrid:GetValue("ZO_CC", nLinha, oModel)

SZ5->(DbSetOrder(1)) // Cód.Posto + Centro de Custo

If !Empty(cCC)
    If !SZ5->(DbSeek(xFilial("SZ5") + cCodPosto + cCC))
        Return .F.
    EndIf
EndIf

oGrid:SetValue("ZO_DESCCC", SubStr(SZ5->Z5_DESCRI,1,150))

Return(.T.)

/*/{Protheus.doc} VldLoc2
Valida o campo Localidade.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function VldLoc()

Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZSDETAIL")
Local nLinha   := oGrid:GetLine()
Local cLocalid := oGrid:GetValue("ZS_LOCALID", nLinha, oModel)

SZ2->(DbSetOrder(2)) // Localidade

If !Empty(cLocalid)
    If !SZ2->(DbSeek(xFilial("SZ5") + cLocalid))
        Return .F.
    EndIf
EndIf

oGrid:SetValue("ZS_DESCLOC", SZ2->Z2_DESCRI)

Return(.T.)

/*/{Protheus.doc} SZELinOk
Valida linha de itens do QQP.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function SZELinOk(oModelGrid)

Local lRet       := .T.
Local oModel     := oModelGrid:GetModel()
Local nOperation := oModel:GetOperation()
Local cItem      := oModelGrid:GetValue("ZE_ITEM")
Local nQuant     := oModelGrid:GetValue("ZE_QUANT")
Local dDataIni   := oModelGrid:GetValue("ZE_DATAINI")

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
    If Empty(cItem) .or. Empty(nQuant)
        Help(,, "NOQQP",, "Entre com o item e quantidade do item da QQP.", 1, 0)
        lRet := .F.
    Endif

    If Empty(dDataIni)
        Help(,, "NOVIGEN",, "Preencha a vigência inicial.", 1, 0)
        lRet := .F.
    Endif
EndIf

Return(lRet)

/*/{Protheus.doc} SZOLinOk
Valida linha de itens do QQP.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function SZOLinOk(oModelGrid)

Local lRet       := .T.
Local oModel     := oModelGrid:GetModel()
Local nOperation := oModel:GetOperation()
Local cCC        := oModelGrid:GetValue("ZO_CC")
Local nPerc      := oModelGrid:GetValue("ZO_PERC")

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
    If Empty(cCC)
        Help(,, "NOCC",, "Preencha o centro de custo.", 1, 0)
        lRet := .F.
    Endif

    If Empty(nPerc)
        Help(,, "NOPERC",, "Preencha percentual do centro de custo.", 1, 0)
        lRet := .F.
    Endif
EndIf

Return(lRet)

/*/{Protheus.doc} SZSLinOk
Valida linha de itens do QQP.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function SZSLinOk(oModelGrid)

Local lRet       := .T.
Local oModel     := oModelGrid:GetModel()
Local nOperation := oModel:GetOperation()
Local cLocalid   := oModelGrid:GetValue("ZS_LOCALID")

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
    If Empty(cLocalid)
        Help(,, "NOLOC",, "Preencha a Localidade.", 1, 0)
        lRet := .F.
    Endif
EndIf

Return(lRet)

/*/{Protheus.doc} TudoOk
Validação antes de salvar o formulário.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function TudoOk(oModel)

Local nOperation := oModel:GetOperation()
Local oModelSZN  := oModel:GetModel("SZNMASTER")
Local cCodigo    := oModelSZN:GetValue("ZN_CODIGO")
Local lRet       := .T.

SZN->(DbSetOrder(1)) // Código

If nOperation == MODEL_OPERATION_INSERT
    If SZN->(DbSeek(xFilial("SZN") + cCodigo))
        Help( ,,"ITREC01",,"Já existe cadastro de itens recorrentes para esse posto avançado / projeto", 1, 0)
        lRet := .F.
    EndIf
EndIf

Return(lRet)
