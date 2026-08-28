#include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} TROCAISSI
Cadastro de Gerências.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function TROCAISSI()

Local oBrowse
Private cAlias := "SZV"

oBrowse := FWMBrowse():New()
oBrowse:SetAlias(cAlias)
oBrowse:SetDescription("Troca de ISSI")

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

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.TROCAISSI" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.TROCAISSI" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Estornar"   ACTION "VIEWDEF.TROCAISSI" OPERATION 5 ACCESS 0

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

oModel := MPFormModel():New("TROCASSIM", /*bPreValidacao*/, /*bPosValidacao*/, { |oMdl| AtuaISSI(oMdl) }, /*bCancel*/ )
oModel:AddFields("FORMSZV",, oStruct)
oModel:SetPrimaryKey({})
oModel:SetDescription("Responsáveis")
oModel:GetModel("FORMSZV"):SetDescription("Formulário de Cadastro de Gerências")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oModel     := FWLoadModel("TROCAISSI")
Local oStruct    := FWFormStruct(2, cAlias)

oView := FWFormView():New()
oView:SetModel(oModel)
oView:AddField("VIEWSZV", oStruct, "FORMSZV")

oView:CreateHorizontalBox("TELA", 100)

oView:SetCloseOnOk({|| .T.})

oView:SetOwnerView("VIEWSZV", "TELA")

Return(oView)

/*/{Protheus.doc} VIEWDEF
Atualiza o campo da descriçao do CC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function AtuaISSI(oModel)

Local nCount     := 0
Local nOperation := oModel:GetOperation()
Local oModelSZV  := oModel:GetModel("FORMSZV")
Local cISSIOri   := AllTrim(oModelSZV:GetValue("ZV_ISSIORI"))
Local cISSINew   := AllTrim(oModelSZV:GetValue("ZV_ISSINEW"))
Local lRetorno   := .T.

SZI->(DbSetOrder(5)) // ISSI + Documento + Item

If nOperation == MODEL_OPERATION_INSERT
    If SZI->(DbSeek(xFilial("SZI") + cISSINew))
        Help( ,,"ISSIEXIST",,"Essa ISSI já está atribuída a outro rádio", 1, 0 )
        lRetorno := .F.
    EndIf

    BeginSQL Alias "SZIQRY"
        SELECT 
            COUNT(*) AS ZI_COUNT
        FROM
            %Table:SZI% SZI
        WHERE
            ZI_STATUS = 'A' AND
            ZI_PATRIM <> '' AND
            ZI_ISSI = %Exp:cISSIOri% AND
            SZI.%NotDel%
    EndSQL

    If !SZIQRY->(EOF())
        nCount := SZIQRY->ZI_COUNT
    End
    SZIQRY->(DbCloseArea())

    If nCount == 0
        Help( ,,"NOISSI",,"Nenhum rádio ativo foi encontrado com essa ISSI.", 1, 0 )
        lRetorno := .F.
    EndIf

    If lRetorno
        BeginTran()

        BeginSQL Alias "SZIQRY"
            SELECT 
                ZI_ISSI, R_E_C_N_O_ AS ZI_RECNO
            FROM
                %Table:SZI% SZI
            WHERE
                ZI_STATUS = 'A' AND
                ZI_ISSI = %Exp:cISSIOri% AND
                SZI.%NotDel%
        EndSQL

        While !SZIQRY->(EOF())
            SZI->(DbGoTo(SZIQRY->ZI_RECNO))

            RecLock("SZI", .F.)
            SZI->ZI_ISSI := cISSINew
            MsUnlock()

            SZIQRY->(DbSkip())
        End
        SZIQRY->(DbCloseArea())

        Endtran()
    EndIf
ElseIf nOperation == MODEL_OPERATION_DELETE
        BeginSQL Alias "SZIQRY"
            SELECT 
                ZI_ISSI, R_E_C_N_O_ AS ZI_RECNO
            FROM
                %Table:SZI% SZI
            WHERE
                ZI_ISSI = %Exp:cISSINew% AND
                SZI.%NotDel%
        EndSQL

        While !SZIQRY->(EOF())
            SZI->(DbGoTo(SZIQRY->ZI_RECNO))

            RecLock("SZI", .F.)
            SZI->ZI_ISSI := cISSIOri
            MsUnlock()

            SZIQRY->(DbSkip())
        End
        SZIQRY->(DbCloseArea())
EndIf

Begin Sequence
    If !(lRetorno := FWFormCommit(oModel))
        cLogMdl := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[6])
        Help( ,,"U_TROCAISSI",,cLogMdl, 1, 0 )
        Break
    EndIf
End Sequence

Return(lRetorno)
