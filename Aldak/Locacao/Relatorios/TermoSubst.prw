#Include "totvs.ch"

User Function TermoSubst()

Local oReport

If !SZH->ZH_STATUS $ "S/R"
    MsgInfo("Esse movimento não é uma substituição.", "Atenção")
    Return
EndIf

oReport := ReportDef()
oReport:PrintDialog()

SZI->(DbSetOrder(1)) // Doc. Origem

Return

Static Function ReportDef()

Local oReport
Local oSection1
Local oSection2
Local oSection3
Local oSection4
Local cTitulo := "Termo de Substituição"

oReport := TReport():New('TermoSubst', cTitulo, /*cPerg*/, {|oReport| PrintReport(oReport)})
oReport:SetPortrait()
oReport:HideParamPage( )
oReport:HideHeader()

// Ajusta a fonte.
oReport:SetLineHeight(50)
oReport:nfontBody := 9

oSection1 := TRSection():New(oReport, 'Info')

oSection2 := TRSection():New(oReport, 'Subst')
TRCell():New(oSection2, "ZI_QUANT",, "Qtd.","", TamSX3("ZI_QUANT")[1])
TRCell():New(oSection2, "B1_DESC",, "Equipamento","", 65)
TRCell():New(oSection2, "ZI_PATRIM",, "Patrimônio","", TamSX3("ZI_PATRIM")[1])
TRCell():New(oSection2, "ZI_NUMSER",, "Núm.Série","", TamSX3("ZI_NUMSER")[1])
TRCell():New(oSection2, "ZI_ISSI",, "ID Rádio","", TamSX3("ZI_ISSI")[1])

oSection3 := TRSection():New(oReport, 'Items')
TRCell():New(oSection3, "ZI_QUANT",, "Qtd.","", TamSX3("ZI_QUANT")[1])
TRCell():New(oSection3, "B1_DESC",, "Equipamento","", 65)
TRCell():New(oSection3, "ZI_PATRIM",, "Patrimônio","", TamSX3("ZI_PATRIM")[1])
TRCell():New(oSection3, "ZI_NUMSER",, "Núm.Série","", TamSX3("ZI_NUMSER")[1])
TRCell():New(oSection3, "ZI_ISSI",, "ID Rádio","", TamSX3("ZI_ISSI")[1])

oSection4 := TRSection():New(oReport, 'Footer')

Return(oReport)

Static Function PrintReport(oReport)

Local oSection1  := oReport:Section(1)
Local oSection2  := oReport:Section(2)
Local oSection3  := oReport:Section(3)
Local oSection4  := oReport:Section(4)
Local nX         := 0
Local cCodPost   := SZH->ZH_CODPOST
Local cLocalid   := SZH->ZH_LOCALID
Local cDoc       := SZH->ZH_DOC
Local cCC        := SZH->ZH_CC
Local cResp		 := SZH->ZH_CODRESP
Local cMotivo	 := SZH->ZH_MOTiVO
Local cCodKit    := ""
Local cDocOri    := ""
Local cDescLoc   := ""
Local aNiveisCC  := {}
Local cDiretoria := ""
Local cGerGeral  := ""
Local cGerArea   := ""
Local cCoordena  := ""
Local cSupervisa := ""
Local cDescKit   := ""
Local cVia       := ""
Local nPageWidth := 2300

SB1->(DbSetOrder(1)) // Código
SZ0->(DbSetOrder(1)) // Cod.posto + Cód. responsável
SZ2->(DbSetOrder(1)) // Cod.posto + Localidade
SZ5->(DbSetOrder(1)) // Cod.posto + Cód. C.C.
SZI->(DbSetOrder(3)) // Do.substituto + Item
Z20->(DbSetOrder(1)) // Código do Kit

// Busca o documento de origem.
If SZI->(DbSeek(xFilial("SZI") + cDoc))
    cDocOri := SZI->ZI_DOC
    cCodKit := SZI->ZI_CODKIT

    If SZ0->(DbSeek(xFilial("SZ0") + cCodPost + cResp))
        cResp := SZ0->Z0_NOME
    EndIf

    If SZ2->(DbSeek(xFilial("SZ2") + cCodPost + cLocalid))
        cDescLoc := SZ2->Z2_DESCRI
    EndIf

    If SZ5->(DbSeek(xFilial("SZ5") + cCodPost + cCC))
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

    SZI->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item

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
        
        oReport:Say(oreport:Row(), 10, "Documento       : " + cDoc)
        oReport:SkipLine(1)

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

        oReport:Say(oreport:Row(), 10, "Motivo          :" + cMotivo)
        oReport:SkipLine(1)

        oReport:Say(oreport:Row(), 10, "Chamado         :" + SZH->ZH_CHAMADO)
        oReport:SkipLine(1)

        oReport:PrtCenter("Substituídos") 
        oReport:SkipLine(1)

        oSection2:Init()

        // Kit substituído.
        cCodKit := ""
        lLocal  := ""
        SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDocOri))
        While SZI->ZI_FILIAL == xFilial("SZI") .and.;
            SZI->ZI_CODPOST == cCodPost .and.;
            SZI->ZI_LOCALID == cLocalid .and.;
            SZI->ZI_DOC == cDocOri .and. !SZI->(EOF())

            If oReport:Cancel()
                Exit
            EndIf

            If SZI->ZI_DOCSUBS <> cDoc
                SZI->(DbSkip())
                Loop
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

        oReport:SkipLine(1)

        // Kit entregue.
        lLocal := ""
        If SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDoc))
            If Z20->(DbSeek(xFilial("Z20") + SZI->ZI_CODKIT))
                cDescKit := Z20->Z20_DESCR
            EndIf

            oReport:PrtCenter("Entregue")
            oReport:SkipLine(1)

            oReport:Say(oreport:Row(), 10, "Kit: " + cDescKit)
            oReport:SkipLine(1)

            oSection3:Init()

            While SZI->ZI_FILIAL == xFilial("SZI") .and.;
                SZI->ZI_CODPOST == cCodPost .and.;
                SZI->ZI_LOCALID == cLocalid .and.;
                SZI->ZI_DOC == cDoc .and. !SZI->(EOF())

                If oReport:Cancel()
                    Exit
                EndIf

            SB1->(DbSeek(xFilial("SB1") + SZI->ZI_PRODUTO))

            If lLocal <> SZI->ZI_LOCALIZ
                lLocal := SZI->ZI_LOCALIZ
                oSection2:Cell("ZI_QUANT"):setValue("")
                oSection2:Cell("B1_DESC"):setValue("Equipto/Localização: " + SZI->ZI_LOCALIZ)
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
        EndIf

        oSection4:Init()

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

        oSection4:Finish()
        oSection3:Finish()
        oSection2:Finish()
        oSection1:Finish()

        oReport:EndPage()
    Next nX
EndIf

Return

Static Function PrintHeader(oReport, cVia)

oReport:PrtRight(DtoC(dDataBase) + " - " + Time())
oReport:SkipLine(1)
oReport:PrtCenter("Termo de Substituição") 
oReport:SkipLine(2)
oReport:PrtRight(cVia) 
oReport:SkipLine(1)
oReport:PrtRight("Página: " + AllTrim(Str(oReport:Page()))) 
oReport:SkipLine(1)

Return
