#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} MOV02
Transferencia de Estoque entre Postos/Localidades.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
User Function MOV02()

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("SZY")
oBrowse:SetDescription("Transferencia de Estoque entre Postos/Localidades")

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opcoes da rotina.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.MOV02" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Transferir" ACTION "VIEWDEF.MOV02" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Estornar"   ACTION "VIEWDEF.MOV02" OPERATION 5 ACCESS 0

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruCab := FWFormStruct(1, "SZY", {|cField| Alltrim(cField) $ "ZY_DOC;ZY_EMISSAO;ZY_POSTORI;ZY_DESCPOR;ZY_LOCORI;ZY_DELOCOR;ZY_POSTDES;ZY_DESCPDE;ZY_LOCDEST;ZY_DELOCDE"})
Local oStruDet := FWFormStruct(1, "SZY", {|cField| !Alltrim(cField) $ "ZY_DOC;ZY_EMISSAO;ZY_POSTORI;ZY_DESCPOR;ZY_LOCORI;ZY_DELOCOR;ZY_POSTDES;ZY_DESCPDE;ZY_LOCDEST;ZY_DELOCDE"})
Local bValidArmOri  := FWBuildFeature(STRUCT_FEATURE_VALID, "U_VArmOri()", .T.)
Local bValidArmDest := FWBuildFeature(STRUCT_FEATURE_VALID, "U_VArmDest()", .T.)
Local bValidProd    := FWBuildFeature(STRUCT_FEATURE_VALID, "U_VProdOri()", .T.)
Local bValidQtd     := FWBuildFeature(STRUCT_FEATURE_VALID, "U_VQtd()", .T.)

oStruCab:SetProperty('ZY_EMISSAO', MODEL_FIELD_INIT, {|| dDataBase})

oStruDet:SetProperty("ZY_ARMORI", MODEL_FIELD_VALID, bValidArmOri)
oStruDet:SetProperty("ZY_ARMDEST", MODEL_FIELD_VALID, bValidArmDest)
oStruDet:SetProperty("ZY_PRODORI", MODEL_FIELD_VALID, bValidProd)
oStruDet:SetProperty("ZY_QUANT", MODEL_FIELD_VALID, bValidQtd)

oModel := MPFormModel():New("MOV02M", /*bPreValidacao*/, /*bPosValidacao*/, {|oMdl| ExecMov(oMdl)}, /*bCancel*/ )

oModel:AddFields("SZYMASTER",, oStruCab)

oModel:AddGrid("SZYDETAIL", "SZYMASTER", oStruDet,, {|oModelGrid| SZYLinOk(oModelGrid)})

oModel:SetRelation("SZYDETAIL", {{"ZY_FILIAL", "xFilial('SZY')"}, {"ZY_DOC", "ZY_DOC"}}, SZY->(IndexKey(1)))

oModel:SetPrimaryKey({})

oModel:SetDescription("Transferencia de Estoque entre Postos/Localidades")
oModel:GetModel("SZYMASTER"):SetDescription("Dados do Cabecalho")
oModel:GetModel("SZYDETAIL"):SetDescription("Dados dos Itens")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruCab := FWFormStruct(2, "SZY", {|cField| Alltrim(cField) $ "ZY_DOC;ZY_EMISSAO;ZY_POSTORI;ZY_DESCPOR;ZY_LOCORI;ZY_DELOCOR;ZY_POSTDES;ZY_DESCPDE;ZY_LOCDEST;ZY_DELOCDE"})
Local oStruDet := FWFormStruct(2, "SZY", {|cField| !Alltrim(cField) $ "ZY_DOC;ZY_EMISSAO;ZY_POSTORI;ZY_DESCPOR;ZY_LOCORI;ZY_DELOCOR;ZY_POSTDES;ZY_DESCPDE;ZY_LOCDEST;ZY_DELOCDE"})
Local oModel   := FWLoadModel("MOV02")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_CAB", oStruCab, "SZYMASTER")
oView:AddGrid("VIEW_DET", oStruDet, "SZYDETAIL")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("GRID", 70)

oView:SetOwnerView("VIEW_CAB", "CABEC")
oView:SetOwnerView("VIEW_DET", "GRID")

Return(oView)

/*/{Protheus.doc} VArmOri
Valida o armazem de origem e carrega o armazem de destino.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
User Function VArmOri()

Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZYDETAIL")
Local cArmOri  := oGrid:GetValue("ZY_ARMORI")
Local cArmDest := oGrid:GetValue("ZY_ARMDEST")
Local lRet     := .T.

SZT->(DbSetOrder(1)) // Local

If Empty(cArmOri)
    Help(,, "ARMVAZIO",, "O campo nao pode ser vazio!", 1, 0)
    lRet := .F.
ElseIf SZT->(DbSeek(xFilial("SZT") + cArmOri))
    If SZT->ZT_SAIDAOK <> "S"
        Help(,, "SAIDANPERM",, "Esse armazem nao permite saida manual!", 1, 0)
        lRet := .F.
    EndIf

    If lRet .and. Empty(cArmDest)
        oGrid:SetValue("ZY_ARMDEST", cArmOri)
    EndIf
Else
    Help(,, "ARMNEXSITE",, "Armazem invalido!", 1, 0)
    lRet := .F.
EndIf

Return(lRet)

/*/{Protheus.doc} VArmDest
Valida o armazem de destino.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
User Function VArmDest()

Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZYDETAIL")
Local cArmDest := oGrid:GetValue("ZY_ARMDEST")
Local lRet     := .T.

SZT->(DbSetOrder(1)) // Local

If Empty(cArmDest)
    Help(,, "ARMVAZIO",, "O campo nao pode ser vazio!", 1, 0)
    lRet := .F.
ElseIf SZT->(DbSeek(xFilial("SZT") + cArmDest))
    If SZT->ZT_ENTRAOK <> "S"
        Help(,, "ENTRANPERM",, "Esse armazem nao permite entrada manual!", 1, 0)
        lRet := .F.
    EndIf
Else
    Help(,, "ARMNEXSITE",, "Armazem invalido!", 1, 0)
    lRet := .F.
EndIf

Return(lRet)

/*/{Protheus.doc} VProdOri
Valida o produto da transferencia.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
User Function VProdOri()

Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZYDETAIL")
Local cProduto := oGrid:GetValue("ZY_PRODORI")
Local lRet     := .T.

SB1->(DbSetOrder(1)) // Codigo

If Empty(cProduto)
    Help(,, "PRDVAZIO",, "Preencha o produto.", 1, 0)
    lRet := .F.
ElseIf SB1->(DbSeek(xFilial("SB1") + cProduto))
    oGrid:SetValue("ZY_DESCPRO", SB1->B1_DESC)
Else
    Help(,, "PRDNOEX",, "Produto invalido!", 1, 0)
    lRet := .F.
EndIf

Return(lRet)

/*/{Protheus.doc} VQtd
Valida a quantidade informada contra o saldo de origem.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
User Function VQtd()

Local oModel   := FWModelActive()
Local oCab     := oModel:GetModel("SZYMASTER")
Local oGrid    := oModel:GetModel("SZYDETAIL")
Local cPostOri := oCab:GetValue("ZY_POSTORI")
Local cLocOri  := oCab:GetValue("ZY_LOCORI")
Local cProduto := oGrid:GetValue("ZY_PRODORI")
Local cArmOri  := oGrid:GetValue("ZY_ARMORI")
Local nQuant   := oGrid:GetValue("ZY_QUANT")
Local lRet     := .T.

SZF->(DbSetOrder(1)) // Cod.Posto + Localidade + Produto + Armazem

If Empty(nQuant)
    Help(,, "QTDZERO",, "Preencha a quantidade.", 1, 0)
    lRet := .F.
ElseIf SZF->(DbSeek(xFilial("SZF") + cPostOri + cLocOri + cProduto + cArmOri))
    If SZF->ZF_SALDO < nQuant
        Help(,, "SALDOINS",, "Quantidade maior do que a disponivel no estoque!", 1, 0)
        lRet := .F.
    EndIf
Else
    Help(,, "NOEST",, "Produto nao encontrado no estoque do posto/localidade de origem!", 1, 0)
    lRet := .F.
EndIf

If lRet .and. U_TemPatrim(cProduto) .and. nQuant > 1
    Help(,, "QTDPAT",, "Produtos que controlam patrimonio devem ser digitados um a um, portanto a quantidade nao pode ser maior do que 1.", 1, 0)
    lRet := .F.
EndIf

Return(lRet)

/*/{Protheus.doc} SZYLinOk
Valida linha de itens da transferencia.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
Static Function SZYLinOk(oModelGrid)

Local lRet       := .T.
Local oModel     := oModelGrid:GetModel()
Local oCab       := oModel:GetModel("SZYMASTER")
Local nOperation := oModel:GetOperation()
Local cPostOri   := oCab:GetValue("ZY_POSTORI")
Local cLocOri    := oCab:GetValue("ZY_LOCORI")
Local cProduto   := oModelGrid:GetValue("ZY_PRODORI")
Local cPatrim    := oModelGrid:GetValue("ZY_PATRIM")
Local cArmOri    := oModelGrid:GetValue("ZY_ARMORI")
Local cArmDest   := oModelGrid:GetValue("ZY_ARMDEST")
Local nQuant     := oModelGrid:GetValue("ZY_QUANT")

SZF->(DbSetOrder(1)) // Cod.Posto + Localidade + Produto + Armazem

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
    If Empty(cProduto)
        Help(,, "PRDVAZIO",, "Preencha o produto.", 1, 0)
        lRet := .F.
    EndIf

    If lRet .and. Empty(cArmOri)
        Help(,, "ARMORIVAZ",, "Preencha o armazem de origem.", 1, 0)
        lRet := .F.
    EndIf

    If lRet .and. Empty(cArmDest)
        Help(,, "ARMDESVAZ",, "Preencha o armazem de destino.", 1, 0)
        lRet := .F.
    EndIf

    If lRet .and. Empty(nQuant)
        Help(,, "QTDZERO",, "Preencha a quantidade.", 1, 0)
        lRet := .F.
    EndIf

    If lRet
        If SZF->(DbSeek(xFilial("SZF") + cPostOri + cLocOri + cProduto + cArmOri))
            If SZF->ZF_SALDO < nQuant
                Help(,, "SALDOINS",, "Quantidade maior do que a disponivel no estoque!", 1, 0)
                lRet := .F.
            EndIf
        Else
            Help(,, "NOEST",, "Produto nao encontrado no estoque do posto/localidade de origem!", 1, 0)
            lRet := .F.
        EndIf
    EndIf

    If lRet .and. Empty(cPatrim) .and. U_TemPatrim(cProduto)
        Help(,, "PATRVAZIO",, "O produto [" + AllTrim(cProduto) + "] controla patrimonio e deve ter o numero informado.", 1, 0)
        lRet := .F.
    EndIf
EndIf

Return(lRet)

/*/{Protheus.doc} ExecMov
Executa a transferencia de estoque entre postos/localidades.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
Static Function ExecMov(oModel)

Local nI         := 0
Local nOperation := oModel:GetOperation()
Local oCab       := oModel:GetModel("SZYMASTER")
Local oGrid      := oModel:GetModel("SZYDETAIL")
Local cPostOri   := oCab:GetValue("ZY_POSTORI")
Local cLocOri    := oCab:GetValue("ZY_LOCORI")
Local cPostDes   := oCab:GetValue("ZY_POSTDES")
Local cLocDest   := oCab:GetValue("ZY_LOCDEST")
Local cProduto   := ""
Local cPatrim    := ""
Local cArmOri    := ""
Local cArmDest   := ""
Local nQuant     := 0
Local cLogMdl    := ""
Local lRetorno   := .T.

SZJ->(DbSetOrder(3)) // Patrimonio

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
    For nI := 1 To oGrid:Length()
        oGrid:GoLine(nI)

        If !oGrid:IsDeleted()
            cProduto := oGrid:GetValue("ZY_PRODORI", nI, oModel)
            cPatrim  := oGrid:GetValue("ZY_PATRIM", nI, oModel)
            cArmOri  := oGrid:GetValue("ZY_ARMORI", nI, oModel)
            cArmDest := oGrid:GetValue("ZY_ARMDEST", nI, oModel)
            nQuant   := oGrid:GetValue("ZY_QUANT", nI, oModel)

            // Saida do estoque do posto/localidade de origem.
            U_GravaEst(cPostOri, cLocOri, cProduto, cArmOri, nQuant, "S")

            // Entrada no estoque do posto/localidade de destino.
            U_GravaEst(cPostDes, cLocDest, cProduto, cArmDest, nQuant, "E")

            // Transfere o patrimonio para o posto/localidade de destino.
            If !Empty(cPatrim)
                If SZJ->(DbSeek(xFilial("SZJ") + cPatrim))
                    RecLock("SZJ", .F.)
                    SZJ->ZJ_CODPOST := cPostDes
                    SZJ->ZJ_LOCALID := cLocDest
                    MsUnlock()
                EndIf
            EndIf
        EndIf
    Next nI
ElseIf nOperation == MODEL_OPERATION_DELETE
    lRetorno := EstornaMov(oModel)

    If !lRetorno
        Return(.F.)
    EndIf
EndIf

Begin Sequence
    If !(lRetorno := FWFormCommit(oModel))
        cLogMdl := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[6])
        Help( ,,"MOV02",,cLogMdl, 1, 0 )
        Break
    EndIf
End Sequence

Return(lRetorno)

/*/{Protheus.doc} EstornaMov
Estorna a transferencia devolvendo saldo e patrimonio para a origem.

@author Ewerton A. Vicentin
@since 19/08/2026
@version P12
/*/
Static Function EstornaMov(oModel)

Local nI       := 0
Local oCab     := oModel:GetModel("SZYMASTER")
Local oGrid    := oModel:GetModel("SZYDETAIL")
Local cPostOri := oCab:GetValue("ZY_POSTORI")
Local cLocOri  := oCab:GetValue("ZY_LOCORI")
Local cPostDes := oCab:GetValue("ZY_POSTDES")
Local cLocDest := oCab:GetValue("ZY_LOCDEST")
Local cProduto := ""
Local cPatrim  := ""
Local cArmOri  := ""
Local cArmDest := ""
Local nQuant   := 0
Local lRet     := .T.

SZJ->(DbSetOrder(3)) // Patrimonio

For nI := 1 To oGrid:Length()
    oGrid:GoLine(nI)

    cProduto := oGrid:GetValue("ZY_PRODORI", nI, oModel)
    cPatrim  := oGrid:GetValue("ZY_PATRIM", nI, oModel)
    cArmOri  := oGrid:GetValue("ZY_ARMORI", nI, oModel)
    cArmDest := oGrid:GetValue("ZY_ARMDEST", nI, oModel)
    nQuant   := oGrid:GetValue("ZY_QUANT", nI, oModel)

    // Devolve o saldo para o posto/localidade de origem.
    U_GravaEst(cPostOri, cLocOri, cProduto, cArmOri, nQuant, "E")

    // Retira o saldo do posto/localidade de destino.
    U_GravaEst(cPostDes, cLocDest, cProduto, cArmDest, nQuant, "S")

    // Devolve o patrimonio para o posto/localidade de origem.
    If !Empty(cPatrim)
        If SZJ->(DbSeek(xFilial("SZJ") + cPatrim))
            RecLock("SZJ", .F.)
            SZJ->ZJ_CODPOST := cPostOri
            SZJ->ZJ_LOCALID := cLocOri
            MsUnlock()
        EndIf
    EndIf
Next nI

Return(lRet)

/*/{Protheus.doc} RetLocTr
Retorna o tipo do local de estoque para filtrar os patrimônios.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function RetLocTr()

Local oModel  := FWModelActive() 
Local oGrid   := oModel:GetModel("SZYDETAIL")
Local cArmOri := oGrid:GetValue("ZY_ARMORI")
Local cTipo   := ""

SZT->(DbSetOrder(1)) // Armazem

If SZT->(DbSeek(xFilial("SZT") + cArmOri))
    cTipo := SZT->ZT_TIPO
EndIf

Return(cTipo)
