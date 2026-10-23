#Validar as tabelas
SELECT *
FROM Support_tickets;

#Total de chamados
SELECT
    COUNT(*) AS total
FROM
    Support_tickets;

--Nível 1
#Quantos chamados existem em cada prioridade? --Dica: GROUP BY + COUNT(*).
SELECT
    priority,
    COUNT(*) AS total_por_prioridade,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets), 1) || '%' AS percentual_por_prioridade
FROM Support_tickets
GROUP BY priority
ORDER BY total_por_prioridade DESC;

#Qual área do produto gera mais chamados? --Dica: mesma estrutura, com ORDER BY ... DESC.
SELECT 
    product_area,
    COUNT(*) AS total_por_area,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets), 1) || '%' AS percentual_por_area
FROM Support_tickets
GROUP BY product_area
ORDER BY COUNT(*) DESC;

#Por qual chegam mais chamados?
SELECT 
	booking_channel,
    COUNT(*) AS total_por_canal,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets), 1) || '%' AS percentual_por_canal
FROM
	Support_tickets
GROUP BY
	booking_channel
ORDER BY
	COUNT(*) DESC;

#Quais dias da semana têm mais volume?
SELECT day_of_week,
COUNT(*) AS total_dias_semana,
ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets), 1) || '%' AS percentual_por_semana
FROM Support_tickets
GROUP BY day_of_week
ORDER BY COUNT(*) DESC;

--Nível 2
#Qual a média de downtime por área do produto?
SELECT 
    product_area,
    ROUND(AVG(downtime_min), 2) AS media_downtime,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets), 1) || '%' AS percentual_dos_chamados
FROM Support_tickets
GROUP BY product_area
ORDER BY AVG(downtime_min) DESC;

#Quantos chamados tiveram impacto em pagamento?
SELECT 
	payment_impact_flag,
    COUNT(*) AS total_pagamento,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets), 1) || '%' AS percentual_pagamento
FROM
	Support_tickets
    GROUP BY payment_impact_flag
    ORDER BY total_pagamento DESC;

#Qual o percentual de chamados high por plano (customer_tier)?
SELECT 
    customer_tier,
    priority,  
    COUNT(*) AS total_prioridade,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets WHERE customer_tier = st.customer_tier), 1) || '%' AS percentual_prioridade
FROM Support_tickets st
WHERE priority = 'high'
GROUP BY customer_tier, priority
ORDER BY customer_tier, COUNT(*) DESC;

#Chamados de empresas Enterprise têm mais prioridade alta que os de Basic? --Dica: mesma estrutura, mas com HAVING.
SELECT
    customer_tier,
    priority,
    COUNT(*) AS Total_prioridades,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets WHERE customer_tier = st.customer_tier), 1) || '%' AS percentual_prioridade
FROM
    support_tickets st
WHERE priority = 'high'
    AND customer_tier IN ('Basic','Enterprise')
GROUP BY customer_tier, priority
ORDER BY customer_tier, COUNT(*) DESC;

--Nível 3
#Em qual setor × região a taxa de erro média é mais alta?
SELECT
    industry,
     region,
    COUNT(*) AS Total_chamados,
    ROUND(AVG(error_rate_pct),1) AS Erro_medio
FROM Support_tickets
GROUP BY industry,region
HAVING COUNT(*) >= 2000
ORDER BY Erro_medio DESC;

#Ter runbook (has_runbook) reduz o tempo de downtime? Dica: --compare AVG(downtime_min) agrupando por essa flag.
SELECT
    has_runbook,
    COUNT(*) AS Total_downtime,
    ROUND(AVG(downtime_min),1) AS downtime_medio
FROM Support_tickets
GROUP BY has_runbook
ORDER BY downtime_medio DESC;

SELECT
    has_runbook,
    product_area,
    COUNT(*) AS Total_downtime,
    ROUND(AVG(downtime_min),1) AS downtime_medio
FROM Support_tickets
GROUP BY has_runbook, product_area
ORDER BY downtime_medio DESC;

#O sentimento negativo se concentra em alguma área do produto?
SELECT 
    product_area,
    COUNT(*) AS Total_chamados,
    ROUND(100.0 * SUM(CASE WHEN customer_sentiment = 'negative' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_negativos
FROM Support_tickets
GROUP BY product_area
ORDER BY pct_negativos DESC;

#Quais empresas concentram mais chamados? Elas pesam mais que o resto? --Dica: GROUP BY company_id + HAVING.
    
SELECT
    company_id,
    COUNT(*) AS Total_chamados,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Support_tickets), 1) || '%' AS pct_do_total
FROM Support_tickets
GROUP BY company_id
HAVING COUNT(*) > 2500
ORDER BY COUNT(*) DESC;

--Nível 4
#Quantos chamados estão sem sentimento? --Dica: tente IS NULL. Se vier zero, olhe se importou como texto vazio ''. É um problema clássico de importação.
SELECT
    customer_sentiment,
    COUNT(*) AS Total_chamados
FROM Support_tickets
WHERE customer_sentiment IS NULL
GROUP BY customer_sentiment
ORDER BY COUNT(*) DESC;

#Existem ticket_id duplicados?
SELECT
    ticket_id,
    COUNT(*) AS Total_duplicado
FROM Support_tickets
GROUP BY ticket_id
HAVING COUNT(*) >1;

SELECT COUNT(*) AS total_linhas, COUNT(DISTINCT ticket_id) AS ids_unicos
FROM Support_tickets;

#Há outliers? (error_rate_pct chega a ~80% e downtime_min a 196; a média está bem abaixo disso.)
SELECT
COUNT(*) AS total_chamados,
    ROUND(MIN(error_rate_pct),1) AS erro_minimo,
    ROUND(MAX(error_rate_pct),1) AS erro_maximo,
    ROUND(AVG(error_rate_pct), 1) AS erro_media,

    MIN(downtime_min) AS downtime_minimo,
    MAX(downtime_min) AS downtime_maximo,
    ROUND(AVG(downtime_min), 1) AS downtime_media
FROM Support_tickets
WHERE downtime_min > 100;

-- Quantos chamados têm downtime curta (menos de 100 caracteres)?
SELECT COUNT(*) AS total
FROM Support_tickets
WHERE downtime_min = 100;

-- Qual a média de downtime só entre os chamados com queda??
SELECT
    SUM(CASE WHEN downtime_min = 0 THEN 1 ELSE 0 END) AS sem_queda,
    SUM(CASE WHEN downtime_min > 0 THEN 1 ELSE 0 END) AS com_queda
FROM Support_tickets;

--Nível 5: o desafio final
Quais características têm mais relação com prioridade alta? Pense em flags, downtime, clientes afetados e plano. Crie uma tabela comparando as médias de cada coluna entre high e low. Ela responde sozinha: “o que define um chamado crítico?”
SELECT
    priority,
    ROUND(AVG(customers_affected), 1) AS clientes_afetados_medio,
    ROUND(AVG(downtime_min), 1) AS downtime_medio,
    ROUND(AVG(error_rate_pct), 1) AS erro_medio,
    ROUND(100.0 * AVG(security_incident_flag) ,1) AS pct_segurança,
    COUNT(*) AS total_chamados,
    ROUND(AVG(org_users), 1) AS usuarios_medio,
    ROUND(100.0 * AVG(has_runbook), 1) AS pct_com_runbook
FROM Support_tickets
GROUP BY priority
ORDER BY CASE priority
     WHEN 'high' THEN 1 
     WHEN 'medium' THEN 2 
     ELSE 3 
     END;



SELECT
    COUNT(x) AS contagem,
    SUM(x) AS soma,
    AVG(x) AS media,
    ROUND(AVG(x) * 1.0, 1) AS media_arredondada
FROM (SELECT 2 AS x UNION ALL SELECT 4 UNION ALL SELECT 7);
