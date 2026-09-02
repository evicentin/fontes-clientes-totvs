#Include "totvs.ch"

/*/{Protheus.doc} TermoEntr
Relatório de Termo de Entrega de Equipamentos.

Pode ser chamado sem parâmetros (utiliza o SZH já posicionado, como no MovLoc)
ou informando a chave do documento (Cód.Posto + Localidade + Documento).

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param cCodPost, character, Código do Posto (opcional)
@param cLocalid, character, Código da Localidade (opcional)
@param cDoc, character, Número do Documento (opcional)
/*/
User Function TermoEntr(cCodPost, cLocalid, cDoc)

Local oReport
Local aAreaSZH := SZH->(GetArea())

Default cCodPost := ""
Default cLocalid := ""
Default cDoc     := ""

If !Empty(cCodPost) .and. !Empty(cLocalid) .and. !Empty(cDoc)
    SZH->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento
    If !SZH->(DbSeek(xFilial("SZH") + cCodPost + cLocalid + cDoc))
        MsgInfo("Documento não localizado.", "Atenção")
        RestArea(aAreaSZH)
        Return
    EndIf
EndIf

If SZH->ZH_STATUS <> "A"
    MsgInfo("Este não é um movimento de Entrega.", "Atenção")
    RestArea(aAreaSZH)
    Return
EndIf

oReport := ReportDef()
oReport:PrintDialog()

RestArea(aAreaSZH)

Return

/*/{Protheus.doc} ReportDef
Relatório de Termo de Entrega de Equipamentos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ReportDef()

Local oReport
Local oSection1
Local oSection2
Local oSection3
Local cTitulo := "Termo de Entrega"

oReport := TReport():New('TermoEntr', cTitulo, /*cPerg*/, {|oReport| PrintReport(oReport)})
oReport:SetPortrait()
oReport:HideParamPage( )
oReport:HideHeader()

// Ajusta a fonte.
oReport:SetLineHeight(50)
oReport:nfontBody := 9

oSection1 := TRSection():New(oReport, 'Info')

oSection2 := TRSection():New(oReport, 'Items')
TRCell():New(oSection2, "ZI_QUANT",, "Qtd.","", TamSX3("ZI_QUANT")[1])
TRCell():New(oSection2, "B1_DESC",, "Equipamento","", 65)
TRCell():New(oSection2, "ZI_PATRIM",, "Patrimônio","", TamSX3("ZI_PATRIM")[1])
TRCell():New(oSection2, "ZI_NUMSER",, "Núm.Série","", TamSX3("ZI_NUMSER")[1])
TRCell():New(oSection2, "ZI_ISSI",, "ID Rádio","", TamSX3("ZI_ISSI")[1])

oSection3 := TRSection():New(oReport, 'Footer')

Return(oReport)

/*/{Protheus.doc} PrintReport
Impressão do Termo de Entrega de Equipamentos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function PrintReport(oReport)

Local oSection1  := oReport:Section(1)
Local oSection2  := oReport:Section(2)
Local oSection3  := oReport:Section(3)
Local nX         := 0
Local cCodPosto  := SZH->ZH_CODPOST
Local cLocalid   := SZH->ZH_LOCALID
Local cDocumento := SZH->ZH_DOC
Local cCC        := SZH->ZH_CC
Local cResp		 := SZH->ZH_CODRESP
Local cCodKit    := ""
Local cDescLoc   := ""
Local aNiveisCC  := {}
Local cDiretoria := ""
Local cGerGeral  := ""
Local cGerArea   := ""
Local cCoordena  := ""
Local cSupervisa := ""
Local cKit       := ""
Local cVia       := ""
Local nPageWidth := 2300

SB1->(DbSetOrder(1)) // Código
SZ0->(DbSetOrder(1)) // Cod.posto + Cód. responsável
SZ2->(DbSetOrder(1)) // Cod.posto + Localidade
SZ5->(DbSetOrder(1)) // Cod.posto + Cód. C.C.
SZI->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item
Z20->(DbSetOrder(1)) // Código do Kit

If SZ0->(DbSeek(xFilial("SZ0") + cCodPosto + cResp))
    cResp := SZ0->Z0_NOME
EndIf

If SZ2->(DbSeek(xFilial("SZ2") + cCodPosto + cLocalid))
    cDescLoc := SZ2->Z2_DESCRI
EndIf

If SZI->(DbSeek(xFilial("SZI") + cCodPosto + cLocalid + cDocumento))
    cCodKit := SZI->ZI_CODKIT
EndIf

If SZ5->(DbSeek(xFilial("SZ5") + cCodPosto + cCC))
    aNiveisCC := U_RetNivelCC(cCC)

    For nX := 1 to Len(aNiveisCC)
        If aNiveisCC[nX, 3] == "1"
            cDiretoria := aNiveisCC[nX, 2]
        ElseIf aNiveisCC[nX, 3] == "2"
            cGerGeral := aNiveisCC[nX, 2]
        ElseIf aNiveisCC[nX, 3] == "3"
            cGerArea := aNiveisCC[nX, 2]
        ElseIf aNiveisCC[nX, 3] == "4"
            cCoordena := aNiveisCC[nX, 2]
        ElseIf aNiveisCC[nX, 3] == "5"
            cSupervisa := aNiveisCC[nX, 2]
        EndIf
    Next nX
EndIf

For nX := 1 to 4
    If nX == 1
        cVia := "1a. Via - Cliente"
    ElseIf nX == 2
        cVia := "2a. Via - Responsável"
    ElseIf nX == 3
        cVia := "3a. Via - Alcon"
    ElseIf nX == 4
        cVia := "4a. Via - Controle"
    EndIf

    oReport:OnPageBreak({|| PrintHeader(oReport, cVia)})

    oSection1:Init()

    oReport:ThinLine()

    oReport:Say(oreport:Row(), 10, "Centro de Custo : " + cCC)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 10, "Diretoria       : " + cDiretoria)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 10, "Gerência Geral  : " + cGerGeral)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 10, "Gerência de Área: " + cGerArea)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 10, "Coordenação     : " + cCoordena)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 10, "Supervisão      : " + cSupervisa)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 10, "Localidade      : " + cDescLoc)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 10, "Responsável     : " + cResp)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 10, "Data            : " + DtoC(SZH->ZH_EMISSAO) + " Operador: " + cUserName)
    oReport:SkipLine(1)

    oReport:ThinLine()

    oReport:Say(oreport:Row(), 10, "Motivo          :" + SZH->ZH_MOTIVO)
    oReport:SkipLine(1)

    // oReport:Say(oreport:Row(), 10, "Kit: " + cKit)
    // oReport:SkipLine(2)

    oSection2:Init()

    cCodKit := ""
    lLocal  := ""
    SZI->(DbSeek(xFilial("SZI") + cCodPosto + cLocalid + cDocumento))
    While SZI->ZI_FILIAL == xFilial("SZI") .and.;
        SZI->ZI_CODPOST == cCodPosto .and.;
        SZI->ZI_LOCALID == cLocalid .and.;
        SZI->ZI_DOC == cDocumento .and. !SZI->(EOF())

        If oReport:Cancel()
            Exit
        EndIf

        SB1->(DbSeek(xFilial("SB1") + SZI->ZI_PRODUTO))

        If SZI->ZI_CODKIT <> cCodKit
            cCodKit := SZI->ZI_CODKIT
            If Z20->(DbSeek(xFilial("Z20") + cCodKit))
                cKit := Z20->Z20_DESCR
            EndIf

            oSection2:Cell("ZI_QUANT"):setValue("")
            oSection2:Cell("B1_DESC"):setValue("")
            oSection2:Cell("ZI_PATRIM"):setValue("")
            oSection2:Cell("ZI_NUMSER"):setValue("")
            oSection2:Cell("ZI_ISSI"):setValue("")
            oSection2:PrintLine()

            oReport:Say(oreport:Row(), 10, "Kit: " + cKit)
            oReport:SkipLine(1)
        Endif

        If lLocal <> SZI->ZI_LOCALIZ
            lLocal := SZI->ZI_LOCALIZ
            oSection2:Cell("ZI_QUANT"):setValue("")
            oSection2:Cell("B1_DESC"):setValue("Localização: " + SZI->ZI_LOCALIZ)
            oSection2:Cell("ZI_PATRIM"):setValue("")
            oSection2:Cell("ZI_NUMSER"):setValue("")
            oSection2:Cell("ZI_ISSI"):setValue("")
            oSection2:PrintLine()

            oSection2:Cell("ZI_QUANT"):setValue(SZI->ZI_QUANT)
            oSection2:Cell("B1_DESC"):setValue(AllTrim(SB1->B1_DESC))
            oSection2:Cell("ZI_PATRIM"):setValue(SZI->ZI_PATRIM)
            oSection2:Cell("ZI_NUMSER"):setValue(SZI->ZI_NUMSER)
            oSection2:Cell("ZI_ISSI"):setValue(SZI->ZI_ISSI)
            oSection2:PrintLine()
        Else
            oSection2:Cell("ZI_QUANT"):setValue(SZI->ZI_QUANT)
            oSection2:Cell("B1_DESC"):setValue(AllTrim(SB1->B1_DESC))
            oSection2:Cell("ZI_PATRIM"):setValue(SZI->ZI_PATRIM)
            oSection2:Cell("ZI_NUMSER"):setValue(SZI->ZI_NUMSER)
            oSection2:Cell("ZI_ISSI"):setValue(SZI->ZI_ISSI)
            oSection2:PrintLine()
        EndIf

        SZI->(DbSkip())
    End

    oSection3:Init()

    oReport:SkipLine(1)
    oReport:Say(oreport:Row(), 10, "Observações")
    oReport:SkipLine(1)

    oReport:Box(oreport:Row() ,10, oreport:Row()+300, nPageWidth)
    oReport:SkipLine(7)

    oReport:Say(oreport:Row(), 10, "Responsável pela entrega (ALCON)")
    oReport:Say(oreport:Row(), 1200, "Responsável pelo Rádio/Equipamento (CLIENTE)")
    oReport:SkipLine(1)

    oReport:Box(oreport:Row() ,10, oreport:Row()+250, 1100)
    oReport:Box(oreport:Row() ,1200, oreport:Row()+250, 2300)
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 15, "Nome legível: ____________________________________")
    oReport:Say(oreport:Row(), 1205, "Nome legível: ____________________________________")
    oReport:SkipLine(1)

    oReport:Say(oreport:Row(), 15, "RG          : ____________________________________")
    oReport:Say(oreport:Row(), 1205, "RG          : ____________________________________")
    oReport:SkipLine(2)

    oReport:Say(oreport:Row(), 15, "Assinatura  : ____________________________________")
    oReport:Say(oreport:Row(), 1205, "Assinatura  : ____________________________________")
    oReport:SkipLine(2)

    oReport:Say(oreport:Row(), 10, "Data: " + DtoC(dDataBase))
    oReport:SkipLine(2)

    oReport:Say(oreport:Row(), 10, "Responsável pelo recebimento e retirada (CLIENTE)")
    oReport:SkipLine(1)

    oReport:Box(oreport:Row() ,10, oreport:Row()+300, nPageWidth)
    oReport:SkipLine(2)

    oReport:Say(oreport:Row(), 15, "Nome legível: ______________________________________________________   Matrícula / RG: ________________________")
    oReport:SkipLine(2)

    oReport:Say(oreport:Row(), 15, "Data: ____/____/____          Assinatura:")
    oReport:SkipLine(2)

    oSection3:Finish()

    oSection2:Finish()
    oSection1:Finish()

    oReport:EndPage()
Next nX

Return

/*/{Protheus.doc} PrintReport
Impressão do Cabeçalho do Termo de 
Entrega de Equipamentos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function PrintHeader(oReport, cVia)

oReport:PrtRight(DtoC(dDataBase) + " - " + Time())
oReport:SkipLine(1)
oReport:PrtCenter("Termo de Entrega") 
oReport:SkipLine(2)
oReport:PrtRight(cVia) 
oReport:SkipLine(1)
oReport:PrtRight("Página: " + AllTrim(Str(oReport:Page()))) 
oReport:SkipLine(1)

Return
