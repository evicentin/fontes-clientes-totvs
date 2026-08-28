#include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} CADRESP
Cadastro de Responsáveis.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function CADRESP()

Local oBrowse
Private cAlias := "SZ0"

oBrowse := FWMBrowse():New()
oBrowse:SetAlias(cAlias)
oBrowse:SetDescription("Cadastro de Responsáveis")

oBrowse:SetFilterDefault(U_MBLocxUsr(1, cAlias))

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opções do Cadastro

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CADRESP" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.CADRESP" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.CADRESP" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.CADRESP" OPERATION 5 ACCESS 0

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

oModel := MPFormModel():New("CADRESPM")
oModel:AddFields("FORMSZ0",, oStruct)
oModel:SetPrimaryKey({"Z0_FILIAL","Z0_CODPOST","Z0_CODRESP"})
oModel:SetDescription("Responsáveis")
oModel:GetModel("FORMSZ0"):SetDescription("Formulário de Cadastro de Responsáveis")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oModel     := FWLoadModel("CADRESP")
Local oStruct    := FWFormStruct(2, cAlias)

oView := FWFormView():New()
oView:SetModel(oModel)
oView:AddField("VIEWSZ0", oStruct, "FORMSZ0")

oView:CreateHorizontalBox("TELA", 100)

oView:SetCloseOnOk({|| .T.})

oView:SetOwnerView("VIEWSZ0", "TELA")

Return(oView)
