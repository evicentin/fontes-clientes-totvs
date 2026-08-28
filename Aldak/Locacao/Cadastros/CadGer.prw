#include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} CADGER
Cadastro de Gerências.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function CADGER()

Local oBrowse
Private cAlias := "SZ6"

oBrowse := FWMBrowse():New()
oBrowse:SetAlias(cAlias)
oBrowse:SetDescription("Cadastro de Gerências")

oBrowse:SetFilterDefault(U_MBLocxUsr(1, cAlias))

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opções do Cadastro

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CADGER" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.CADGER" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.CADGER" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.CADGER" OPERATION 5 ACCESS 0

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruct := FWFormStruct(1, cAlias)

oModel := MPFormModel():New("CADGERM")
oModel:AddFields("FORMSZ6",, oStruct)
oModel:SetPrimaryKey({"Z6_FILIAL","Z6_CODPOST","Z6_CODIGO"})
oModel:SetDescription("Responsáveis")
oModel:GetModel("FORMSZ6"):SetDescription("Formulário de Cadastro de Gerências")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oModel     := FWLoadModel("CADGER")
Local oStruct    := FWFormStruct(2, cAlias)

oView := FWFormView():New()
oView:SetModel(oModel)
oView:AddField("VIEWSZ6", oStruct, "FORMSZ6")

oView:CreateHorizontalBox("TELA", 100)

oView:SetCloseOnOk({|| .T.})

oView:SetOwnerView("VIEWSZ6", "TELA")

Return(oView)

