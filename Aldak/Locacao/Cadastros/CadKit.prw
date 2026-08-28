#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} CADKIT
Kits x Posto Avançado.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function CADKIT()

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("SZ7")
oBrowse:SetDescription("Kits x Posto Avançado")

oBrowse:SetFilterDefault(U_MBLocxUsr(1, "SZ7"))

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opções do Cadastro

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MenuDef()

Local aRotina := FWMVCMenu("CADKIT")

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruSZ7 := FWFormStruct(1, "SZ7")
Local oStruSZ8 := FWFormStruct(1, "SZ8")

oModel := MPFormModel():New("CADKITM")

oStruSZ7:SetProperty("Z7_CODPOST", MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "U_VALIDPOS()"))

oModel:AddFields("SZ7MASTER",, oStruSZ7)

oModel:AddGrid("SZ8DETAIL", "SZ7MASTER", oStruSZ8,, {|oModelGrid| SZ8LinOk(oModelGrid)})

oModel:SetRelation("SZ8DETAIL", {{"Z8_FILIAL", "xFilial('SZ8')"}, {"Z8_CODPOST", "Z7_CODPOST"}}, SZ8->(IndexKey(1)))

oModel:SetPrimaryKey({"Z7_FILIAL","Z7_CODPOST"})

oModel:SetDescription("Kits x Posto Avançado")
oModel:GetModel("SZ7MASTER"):SetDescription("Dados do Posto")
oModel:GetModel("SZ8DETAIL"):SetDescription("Dados dos Kits")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZ7   := FWFormStruct(2, "SZ7")
Local oStruSZ8   := FWFormStruct(2, "SZ8", {|x| !AllTrim(x) $ "Z8_CODPOST"})
Local oModel     := FWLoadModel("CADKIT")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZ7", oStruSZ7, "SZ7MASTER")
oView:AddGrid("VIEW_SZ8", oStruSZ8, "SZ8DETAIL")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("GRID", 70)

oView:SetOwnerView("VIEW_SZ7", "CABEC")
oView:SetOwnerView("VIEW_SZ8", "GRID")

Return(oview)

/*/{Protheus.doc} VALIDPOS
Carrega dados da linha amterior na linha atual.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function VALIDPOS()

Local oModel   := FWModelActive()
Local oForm    := oModel:GetModel("SZ7MASTER")
Local cCodPost := oForm:GetValue("Z7_CODPOST")

SZ7->(DbSetOrder(1))

If !Empty(cCodPost)
    If SZ7->(DbSeek(xFilial("SZ7") + cCodPost))
        Help(,, "INVALIDPOST",, "Já existe cadastro para esse posto avançado, você deve alterar o cadastro exisente.", 1, 0)
        Return(.F.)
    EndIf
EndIf

Return(.T.)

/*/{Protheus.doc} SZ8LinOk
Valida linha dos kits.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function SZ8LinOk(oModelGrid)

Local lRet       := .T.
Local oModel     := oModelGrid:GetModel()
Local nOperation := oModel:GetOperation()
Local cKit       := oModelGrid:GetValue("Z8_CODIGO")
Local cItem01    := oModelGrid:GetValue("Z8_ITQQP01")
Local cItem02    := oModelGrid:GetValue("Z8_ITQQP02")
Local cItem03    := oModelGrid:GetValue("Z8_ITQQP03")
Local dDataIt01  := oModelGrid:GetValue("Z8_DTLIM01")
Local dDataIt02  := oModelGrid:GetValue("Z8_DTLIM02")
Local dDataIt03  := oModelGrid:GetValue("Z8_DTLIM03")

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
    If Empty(cKit)
        Help(,, "NOLOC",, "Preencha o kit.", 1, 0)
        lRet := .F.
    Endif

    If !Empty(cItem01) .and. Empty(dDataIt01)
        Help(,, "NODTIT01",, "Preencha a data limite do item 01.", 1, 0)
        lRet := .F.
    EndIf

    If !Empty(cItem02) .and. Empty(dDataIt02)
        Help(,, "NODTIT02",, "Preencha a data limite do item 02.", 1, 0)
        lRet := .F.
    EndIf

    If !Empty(cItem03) .and. Empty(dDataIt03)
        Help(,, "NODTIT03",, "Preencha a data limite do item 03.", 1, 0)
        lRet := .F.
    EndIf
EndIf

Return(lRet)
