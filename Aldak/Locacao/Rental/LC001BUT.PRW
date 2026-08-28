#INCLUDE "TopConn.ch"
#INCLUDE 'totvs.ch'
#INCLUDE 'Protheus.ch'
#INCLUDE "TBICONN.CH"

//author Jose Eulalio
//05/11/2021

User Function LC001BUT()

Local aRotinaNew	:= PARAMIXB[1]
Local nPosOption	:= PARAMIXB[2]

//Relatório Resumo de faturamento
aAdd(aRotinaNew , {"ANALITIC"      ,{||U_ALCR001()}    ,OemToAnsi("ALC-Resumo Faturamento" ),OemToAnsi("ALC-Resumo Faturamento")})
aAdd(aRotinaNew , {"ANALITIC"      ,{||U_ALCR01GR()}   ,OemToAnsi("ALC-Totalizador" )       ,OemToAnsi("ALC-Totalizador")       })
aAdd(aRotinaNew , {"Pesq. Equip."  ,{||U_INTS001()}    ,OemToAnsi("ALC-Pesq. Equip.BP")     ,OemToAnsi("ALC-Pesq. Equip.BP")    })
aAdd(aRotinaNew , {"QuadroResumo"  ,{||U_CADZ42()}     ,OemToAnsi("ALC-QQP do CTR")         ,OemToAnsi("ALC-QQP do CTR")        })

If nPosOption == 4
    //AAdd(aRotinaNew , {"AUTOM"  , {||U_FCriaFPA()}  ,OemToAnsi("Replicar Linhas" )      ,OemToAnsi("Replicar Linhas"    )})
    AAdd(aRotinaNew , {"AUTOM"  , {||U_KITMOD3()}   ,OemToAnsi("ALC-Kit de Produtos" )      ,OemToAnsi("ALC-Kit de Produtos"    )})
EndIf
//aAdd(aRotinaNew , {"ANALITIC",{||U_fzfacert()} , OemToAnsi("arruamfonte" ),OemToAnsi("arrumafonte")})
If nPosOption == 2
    aAdd(aRotinaNew , {"ANALITIC",{||U_ALCDTFPA()}    ,OemToAnsi("ALC-Ajust.DT Medição" ),OemToAnsi("ALC-Ajust.DT Medição")})    
EndIf

Return(aRotinaNew)
