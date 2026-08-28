#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} MOV01
Movimentos de Estoque das Localidades.
@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function MOV01()

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("SZU")
oBrowse:SetDescription("Movimentos de Estoque")

oBrowse:SetFilterDefault(U_MBLocxUsr(1, "SZU"))

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

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.MOV01" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Transferir"    ACTION "VIEWDEF.MOV01" OPERATION 3 ACCESS 0

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruCab   := FWFormStruct(1, "SZU", {|cField| Alltrim(cField) $ "ZU_CODPOST;ZU_DESCPOS;ZU_LOCALID;ZU_DESCLOC;ZU_DATA,ZU_CHAVNFE"})
Local oStruDet   := FWFormStruct(1, "SZU", {|cField| !Alltrim(cField) $ "ZU_CODPOST;ZU_DESCPOS;ZU_LOCALID;ZU_DESCLOC;ZU_DATA,ZU_CHAVNFE"})
Local bValidOri  := FWBuildFeature(STRUCT_FEATURE_VALID, "U_ValidOri()", .T.)
Local bValidDest := FWBuildFeature(STRUCT_FEATURE_VALID, "U_ValidDest()", .T.)
Local bValidProd := FWBuildFeature(STRUCT_FEATURE_VALID, "U_ValidProd()", .T.)
Local bValidQtd  := FWBuildFeature(STRUCT_FEATURE_VALID, "U_ValidQtd()", .T.)

oStruCab:SetProperty('ZU_DATA', MODEL_FIELD_INIT , {|| dDataBase})

oStruDet:SetProperty("ZU_ARMORI", MODEL_FIELD_VALID, bValidOri)
oStruDet:SetProperty("ZU_ARMDEST", MODEL_FIELD_VALID, bValidDest)
oStruDet:SetProperty("ZU_PRODUTO", MODEL_FIELD_VALID, bValidProd)
oStruDet:SetProperty("ZU_QUANT", MODEL_FIELD_VALID, bValidQtd)

oModel := MPFormModel():New("MOV01M", /*bPreValidacao*/, /*bPosValidacao*/, {|oMdl| ExecMov(oMdl)}, /*bCancel*/ )

oModel:AddFields("SZUMASTER",, oStruCab)

oModel:AddGrid("SZUDETAIL", "SZUMASTER", oStruDet,, {|oModelGrid| SZULinOk(oModelGrid)})

oModel:SetRelation("SZUDETAIL", {{"ZU_FILIAL", "xFilial('SZU')"},{"ZU_CODPOST", "ZU_CODPOST"},{"ZU_LOCALID", "ZU_LOCALID"},;
    {"ZU_DATA", "ZU_DATA"}}, SZU->(IndexKey(1)))

oModel:SetPrimaryKey({})

oModel:SetDescription("Movimentos de Estoque")
oModel:GetModel("SZUMASTER"):SetDescription("Dados do Caebçalho")
oModel:GetModel("SZUDETAIL"):SetDescription("Dados dos Itens")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruCab   := FWFormStruct(2, "SZU", {|cField| Alltrim(cField) $ "ZU_CODPOST;ZU_DESCPOS;ZU_LOCALID;ZU_DESCLOC;ZU_DATA,ZU_CHAVNFE"})
Local oStruDet   := FWFormStruct(2, "SZU", {|cField| !Alltrim(cField) $ "ZU_CODPOST;ZU_DESCPOS;ZU_LOCALID;ZU_DESCLOC;ZU_DATA;ZU_LOG,ZU_CHAVNFE"})
Local oModel     := FWLoadModel("MOV01")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_CAB", oStruCab, "SZUMASTER")
oView:AddGrid("VIEW_DET", oStruDet, "SZUDETAIL")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("GRID", 70)

oView:SetOwnerView("VIEW_CAB", "CABEC")
oView:SetOwnerView("VIEW_DET", "GRID")

Return(oview)

/*/{Protheus.doc} ValidOri
Valida armazém de origem.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function ValidOri()
Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZUDETAIL")
Local cArmOri  := oGrid:GetValue("ZU_ARMORI")
Local cArmDest := oGrid:GetValue("ZU_ARMDEST")
Local lRet     := .T.

SZT->(DbSetOrder(1)) // Local

If Empty(cArmOri)
    Help(,, "ARMVAZIO",, "O campo não pode ser vazio!", 1, 0)
    lRet := .F.
EndIf

If SZT->(DbSeek(xFilial("SZT") + cArmOri))
    If SZT->ZT_SAIDAOK <> "S"
        Help(,, "SAIDANPERM",, "Esse armazém não permite saída manual!", 1, 0)
        lRet := .F.
    EndIf

    If !Empty(cArmOri) .and. cArmOri == cArmDest
        Help(,, "NOARMEQ",, "O armazém de origem não pode ser igual ao de destino!", 1, 0)
        lRet := .F.
    EndIf
else
    Help(,, "ARMNEXSITE",, "Armazém inválido!", 1, 0)
    lRet := .F.
EndIf

Return lRet

/*/{Protheus.doc} ValidDest
Valida armazém de destino.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function ValidDest()
Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZUDETAIL")
Local cArmOri  := oGrid:GetValue("ZU_ARMORI")
Local cArmDest := oGrid:GetValue("ZU_ARMDEST")
Local lRet     := .T.

SZT->(DbSetOrder(1)) // Local

If Empty(cArmDest)
    Help(,, "ARMVAZIO",, "O campo não pode ser vazio!", 1, 0)
    lRet := .F.
EndIf

If SZT->(DbSeek(xFilial("SZT") + cArmDest))
    If SZT->ZT_ENTRAOK <> "S"
        Help(,, "ENTRANPERM",, "Esse armazém não permite entrada manual!", 1, 0)
        lRet := .F.
    EndIf

    If !Empty(cArmOri) .and. cArmOri == cArmDest
        Help(,, "NOARMEQ",, "O armazém de origem não pode ser igual ao de destino!", 1, 0)
        lRet := .F.
    EndIf
else
    Help(,, "ARMNEXSITE",, "Armazém inválido!", 1, 0)
    lRet := .F.
EndIf

Return lRet

/*/{Protheus.doc} ValidProd
Valida o produto.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function ValidProd()
Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZUDETAIL")
Local cProduto := oGrid:GetValue("ZU_PRODUTO")
Local lRet     := .T.

SB1->(DbSetOrder(1)) // Código

If SB1->(DbSeek(xFilial("SB1") + cProduto))
    oGrid:SetValue("ZU_DESCRI", SB1->B1_DESC)
else
    Help(,, "PRDNOEX",, "Produto inválido!", 1, 0)
    lRet := .F.
EndIf

Return lRet

/*/{Protheus.doc} ValidProd
Valida o produto.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function ValidQtd()
Local oModel   := FWModelActive()
Local oCab     := oModel:GetModel("SZUMASTER")
Local oGrid    := oModel:GetModel("SZUDETAIL")
Local cCodPost := oCab:GetValue("ZU_CODPOST")
Local cLocalid := oCab:GetValue("ZU_LOCALID")
Local cProduto := oGrid:GetValue("ZU_PRODUTO")
Local cArmOri  := oGrid:GetValue("ZU_ARMORI")
Local nQuant   := oGrid:GetValue("ZU_QUANT")
Local lRet     := .T.

SZF->(DbSetOrder(1)) // Cód.Posto + Localidade + Produto + Armazém

If SZF->(DbSeek(xFilial("SZF") + cCodPost + cLocalid + cProduto + cArmOri))
    If SZF->ZF_SALDO < nQuant
        Help(,, "SALDOINS",, "Quantidade maior do que a disponível no estoque!", 1, 0)
        lRet := .F.
    EndIf
EndIf

If U_TemPatrim(cProduto) .and. nQuant > 1
    Help(,, "QTDPAT",, "Produtos que controlam patrimônio tem que ser digitado um a um, portanto, a quantidade não pode ser maior do que 1.", 1, 0)
    lRet := .F.
EndIf

Return lRet

/*/{Protheus.doc} SZULinOk
Valida linha de itens do QQP.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function SZULinOk(oModelGrid)

Local lRet       := .T.
Local oModel     := oModelGrid:GetModel()
Local oCab       := oModel:GetModel("SZUMASTER")
Local cCodPost   := oCab:GetValue("ZU_CODPOST")
Local cLocalid   := oCab:GetValue("ZU_LOCALID")
Local nOperation := oModel:GetOperation()
Local cProduto   := oModelGrid:GetValue("ZU_PRODUTO")
Local cPatrim    := oModelGrid:GetValue("ZU_PATRIM")
Local cArmOri    := oModelGrid:GetValue("ZU_ARMORI")
// Local cChaveNFe  := oModelGrid:GetValue("ZU_CHAVNFE")
Local nQuant     := oModelGrid:GetValue("ZU_QUANT")
// Local cArmDest   := oModelGrid:GetValue("ZU_ARMDEST")

SZF->(DbSetOrder(1)) // Cód.Posto + Localidade + Produto + Armazém
SZJ->(DbSetOrder(1)) // Patrimonio
// SZT->(DbSetOrder(1)) // Local

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
    If Empty(nQuant)
        Help(,, "QTDZERO",, "Preencha a quantidade.", 1, 0)
        lRet := .F.
    Endif

    If SZF->(DbSeek(xFilial("SZF") + cCodPost + cLocalid + cProduto + cArmOri))
        If SZF->ZF_SALDO < nQuant
            Help(,, "SALDOINS",, "Quantidade maior do que a disponível no estoque!", 1, 0)
            lRet := .F.
        EndIf
    else
        Help(,, "NOEST",, "Produto não encontrado no estoque dessa localidade!", 1, 0)
        lRet := .F.
    EndIf    

    If Empty(cProduto)
        Help(,, "PRDNOEX",, "Preencha o produto.", 1, 0)
        lRet := .F.
    Else
        if Empty(cPatrim)
            If U_TemPatrim(cProduto)
                Help(,, "PATRVAZIO",, "O produto [" + AllTrim(cProduto) + "] controla patrimônio e deve ter o número informado.", 1, 0)
                lRet := .F.
            EndIf
        EndIf
    EndIf

    // If SZT->(DbSeek(xFilial("SZT") + cArmDest))
    //     If SZT->ZT_CHAVENF == "S" .and. Empty(cChaveNFe)
    //         Help(,, "NOCHVNFE",, "Preencha a chave da NF-e.", 1, 0)
    //         lRet := .F.
    //     Endif
    // EndIf
EndIf

Return(lRet)

/*/{Protheus.doc} ExecMov
Executa a movimentação dos estoques.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ExecMov(oModel)

Local nI         := 0
Local nOperation := oModel:GetOperation()
Local oCab       := oModel:GetModel("SZUMASTER")
Local oGrid      := oModel:GetModel("SZUDETAIL")
Local cCodPost   := oCab:GetValue("ZU_CODPOST")
Local cLocalid   := oCab:GetValue("ZU_LOCALID")
Local cChaveNFe  := oCab:GetValue("ZU_CHAVNFE")
Local cProduto   := oGrid:GetValue("ZU_PRODUTO")
Local cPatrim    := oGrid:GetValue("ZU_PATRIM")
Local cArmOri    := oGrid:GetValue("ZU_ARMORI")
Local cArmDest   := oGrid:GetValue("ZU_ARMDEST")
Local nQuant   := oGrid:GetValue("ZU_QUANT")
Local lRetorno   := .T.

SZJ->(DbSetOrder(3)) // Patrimônio
SZT->(DbSetOrder(1)) // Local

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
    If SZT->(DbSeek(xFilial("SZT") + cArmDest))
        If AllTrim(SZT->ZT_CHAVENF) == "S" .and. Empty(cChaveNFe)
            Help(,, "NOCHVNFE",, "Preencha a chave da NF-e.", 1, 0)
            Return(.F.)
        Endif
    EndIf

	For nI := 1 To oGrid:Length()
		oGrid:GoLine(nI)

        if !oGrid:IsDeleted()
            cPatrim  := oGrid:GetValue("ZU_PATRIM", nI, oModel)
            cProduto := oGrid:GetValue("ZU_PRODUTO", nI, oModel)

            If !oGrid:IsDeleted()
                U_GravaEst(cCodPost, cLocalid, cProduto, cArmOri, nQuant, "S")
                U_GravaEst(cCodPost, cLocalid, cProduto, cArmDest, nQuant, "E")

                If SZJ->(DbSeek(xFilial("SZJ") + cPatrim))
                    RecLock("SZJ", .F.)
                    SZJ->ZJ_LOCADO := SZT->ZT_TIPO
                    MsUnlock()
                EndIf
            EndIf
        EndIf
	Next nI
EndIf

Begin Sequence
    If !(lRetorno := FWFormCommit(oModel))
        cLogMdl := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[6])
        Help( ,,"MOV01",,cLogMdl, 1, 0 )
        Break
    EndIf
End Sequence

Return(lRetorno)

/*/{Protheus.doc} RetLoc
Retorna o tipo do local de estoque para filtrar os patrimônios.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function RetLoc()

Local oModel  := FWModelActive() 
Local oGrid   := oModel:GetModel("SZUDETAIL")
Local cArmOri := oGrid:GetValue("ZU_ARMORI")
Local cTipo   := ""

SZT->(DbSetOrder(1)) // Armazem

If SZT->(DbSeek(xFilial("SZT") + cArmOri))
    cTipo := SZT->ZT_TIPO
EndIf

Return(cTipo)
