CREATE TABLE manuals(id BIGSERIAL PRIMARY KEY,title TEXT NOT NULL,manufacturer TEXT NOT NULL,model TEXT NOT NULL,version TEXT NOT NULL,content TEXT NOT NULL,source TEXT NOT NULL);
CREATE TABLE manual_chunks(id BIGSERIAL PRIMARY KEY,manual_id BIGINT NOT NULL REFERENCES manuals(id),page_number INT NOT NULL,section TEXT NOT NULL,content TEXT NOT NULL,source TEXT NOT NULL);
CREATE TABLE cases(id BIGSERIAL PRIMARY KEY,pharmacy TEXT NOT NULL,robot TEXT NOT NULL,version TEXT NOT NULL,problem TEXT NOT NULL,symptoms TEXT NOT NULL,diagnosis TEXT NOT NULL,cause TEXT NOT NULL,solution TEXT NOT NULL,result TEXT NOT NULL,evidence TEXT NOT NULL,validated BOOLEAN NOT NULL DEFAULT true,closed_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX manuals_search ON manuals USING GIN(to_tsvector('simple',title||' '||content));
CREATE INDEX chunks_search ON manual_chunks USING GIN(to_tsvector('simple',section||' '||content));
INSERT INTO manuals(title,manufacturer,model,version,content,source) VALUES ('Guía técnica por averías - motores nuevos','Documento proporcionado por el usuario','Ejes P/S/B','1','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
GUIA TECNICA SIMPLE POR AVERIAS
Parametrizacion de ejes, cambio de correas, motores, cuernecillos, barrera de luz y ultrasonido
Criterio de esta version
Se han eliminado terminos confusos. Donde antes se decia "emulador", ahora se habla de amplificador de luz / amplificador de fibra 
optica. Cada averia empieza en pagina nueva y solo contiene lo necesario para ejecutarla.
Indice rapido
Averia Trabajo
1 Parametrizar conjuntamente los ejes P, S y B.
2 Cambiar correa/corona blanca 20 dientes <-> negra 16 dientes.
3 Cambio de cuernecillos + barrera de luz/amplificador de fibra optica + limite del eje S.
4 Cambio de motores paso a paso en ejes S, P y B.
5 Comprobacion y ajuste de ultrasonido.
Antes de tocar parametros
Anotar los valores actuales de la base de datos y de MACH4_Ctrl. Trabajar siempre en manual, con velocidad baja y comprobacion 
visual del conjunto.

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
AVERIA 1 - Parametrizar conjuntamente los ejes P, S y B
Imagen de apoyo: conjunto fisico de pinza y ejes P/S/B.
Captura de referencia: pantalla Greifer para mover ejes y leer valores.
Objetivo
 Dejar alineados S y B.
 Ajustar apertura real del eje P.
 Guardar limites AG+/KG+/AG-/KG- con valores practicos.
 Comprobar palas, lanza y ventosa sin roces ni golpes.
Parametrizacion ordenada por ejes
Orden de trabajo: comprobar primero S-Achse como referencia, despues ajustar B-Achse en funcion de S, y finalmente ajustar P-
Achse para la apertura real de palas.

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
Nota previa: comprobar primero el Nullpunkt del eje S. En sistemas normales debe estar en 135; en sistemas MP, S-Multipicking 
debe estar en 35; en sistemas nuevos, verificar si debe quedar a 0 antes de ajustar B.
1. S-Achse - comprobacion inicial, limites de lanza y barrera de luz
Parametro / punto Que hacer Valor / criterio
AG- Llevar S y B completos hacia atras. Leer valor 
Greifer del eje S. AG- = Greifer S + 1,5.
KG- Mismo punto fisico que AG-. KG- = Greifer S + 1,5.
Save_Pos Dejar posicion segura desde el limite trasero. Save_Pos = AG- + 1.
AG+ Llevar S y B completos hacia delante. Leer valor 
Greifer del eje S. AG+ = Greifer S - 1,5.
KG+ Limite positivo de seguridad del eje S. Despues 
comprobar barrera de luz. KG+ = 340 siempre.
Barrera de luz Comprobar que la senal cambia en el punto 
correcto. Parametro: Greifer S-Achse LichtSchranke.
2. B-Achse - alineacion del conjunto
Parametro / punto Que hacer Valor / criterio
Nullpunkt B Adelantar palas y ventosa hasta dejarlas paralelas. 
B se usa como referencia para alinear el conjunto. Eje S aprox. 135. S-Multipicking aprox. 35.
Correccion de Nullpunkt B Leer valor S y valor B. Calcular diferencia y corregir 
el Nullpunkt de B. X = S - B. Restar X al Nullpunkt de B.
AG- / KG- Con S y B completos hacia atras, ajustar limites 
traseros del eje B. Valor Greifer + 1,5. Save_Pos = AG- + 1.
AG+ / KG+ Con S y B completos hacia delante, ajustar limites 
delanteros del eje B.
Valor Greifer - 1,5. KG+ coherente con el limite 
delantero si aplica.
3. P-Achse - apertura real de palas
Parametro / punto Que hacer Valor / criterio
Nullpunkt P Medir con calibre de 60 mm. Poner palas a 60 mm y 
comprobar lectura Greifer.
Si Greifer no marca 60, corregir con + o - en 
Nullpunkt P.
AG- Ajustar minimo de trabajo de palas. AG- = 12. Si da problemas o choca con ventosa, 
usar 14.
KG- Ajustar minimo de seguridad de palas. KG- = 14.
Save_Pos Dejar posicion segura dentro del limite positivo 
usado. Save_Pos = 1 mm dentro de KG+ o AG+.
4. Prueba conjunta antes de cerrar
Eje / elemento Comprobacion fisica
S-Achse / lanza Llevar la lanza completa hacia delante y completa hacia atras. No debe golpear, 
forzar ni perder pasos.
S-Achse / barrera Tras KG+ = 340, comprobar que Greifer S-Achse LichtSchranke cambia en el 
punto correcto.
B-Achse Mover B junto con S hacia delante y hacia atras. Confirmar paralelo y sin roces.
P-Achse / palas Abrir palas completamente y cerrarlas completamente. Verificar 60 mm con 
calibre.
Ventosa Con palas adelantadas/cerradas, verificar que no choque con palas, cuernecillos 
ni zona de barrera.
Conjunto Repetir movimientos combinados S + B + P a baja velocidad antes de cerrar.
Criterio de cierre
La parametrizacion debe cerrarse eje por eje: primero S para confirmar la referencia del conjunto, despues B para dejarlo 
alineado en funcion de S, y finalmente P para apertura real de palas. No cerrar la averia hasta probar S + B + P combinados a 
baja velocidad, con lanza delante/atras y palas abiertas/cerradas.

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
AVERIA 2 - Cambio de correa/corona blanca 20 <-> negra 16
Captura de referencia: tabla ACHSPAR en IBExpert.
Trabajo fisico
1. Confirmar sentido del cambio: blanca 20 -> negra 16 o negra 16 -> blanca 20.
2. Parar maquina y trabajar en seguro.
3. Retirar correa/corona antigua.
4. Montar correa/corona nueva verificando asiento correcto en los dientes.
5. Comprobar tension: sin holgura excesiva y sin tensar de mas.
6. Mover manualmente el eje afectado y revisar que no haya saltos de dientes ni puntos duros.
Tabla ACHSPAR que se modifica
Eje Configuracion Zaehne ZModul Getriebe
S-Achse Blanca - 20 dientes 20 2.5 1.0
S-Achse Negra - 16 dientes 16 3.0 1.0
P-Achse Blanca - 20 dientes 20 5.0 1.0
P-Achse Negra - 16 dientes 16 6.0 1.0
B-Achse Blanca - 20 dientes 20 2.5 1.0
B-Achse Negra - 16 dientes 16 3.0 1.0
Ejes que no se tocan por este cambio
Para el cambio 20 <-> 16 solo se modifican S-Achse, P-Achse y B-Achse. No modificar C-Achse ni D-Achse por esta averia.

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
Comprobacion final
 Guardar cambios.
 Recargar parametros o reiniciar control si procede.
 Referenciar ejes.
 Mover eje a baja velocidad.
 Comprobar palas abiertas/cerradas y lanza adelante/atras.
 Realizar prueba con paquete.

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
AVERIA 3 - Cambio de cuernecillos + barrera de luz/amplificador + 
limite del eje S
Captura de referencia: pantalla Greifer para mover S y comprobar senal de barrera de luz.
Objetivo
 Cambiar cuernecillos.
 Comprobar que no hay roces con palas, lanza ni ventosa.
 Configurar/verificar barrera de luz con el amplificador de luz o fibra optica.
 Comprobar el limite del eje S despues del ajuste.
Cambio fisico de cuernecillos
7. Parar maquina y trabajar en seguro.
8. Retirar cuernecillos antiguos.
9. Limpiar apoyo y revisar rebabas, deformaciones o restos.
10. Montar cuernecillos nuevos en la misma orientacion.
11. Apretar sin deformar la pieza.
12. Mover manualmente palas y lanza para verificar que no roza ni tapa la barrera.
Fijacion tras ajuste
Cuando el ajuste quede validado, aplicar esmalte de unas en el punto de fijacion/tornilleria para dejar marcada y fijada la posicion.
Barrera de luz: parametro real en base de datos
Elemento Nombre a usar en la guia
Parametro Greifer S-Achse LichtSchranke
Metodo Mover eje S en Greifer hasta encontrar el ultimo valor que enciende la barrera. Guardar ese 
valor - 1 toque/paso.
Comprobacion Avanzar y retroceder varias veces. La senal debe cambiar siempre en el mismo punto.
Amplificador de luz / fibra optica
 No llamarlo emulador en la guia.
 Comprobar en el amplificador que la senal cambia de libre a cortada de forma estable.
 Si el amplificador cambia pero MACH4_Ctrl no cambia, revisar entrada, cableado o comunicacion con el control.

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
 Si MACH4_Ctrl cambia pero fisicamente falla la deteccion, revisar alineacion, fibra, suciedad, cuernecillos o distancia.
Comprobacion del limite del eje S
Paso Comprobacion
1 Llevar S hacia la zona de barrera lentamente.
2 Confirmar que la barrera se enciende antes de que haya golpe o roce.
3 Confirmar que los cuernecillos no tapan la barrera fuera de tiempo.
4 Verificar KG+ del eje S = 340 cuando aplique.
5 Repetir con palas abiertas y cerradas.
Prueba final de la averia
 Cuernecillos firmes, alineados y fijados con esmalte tras validar.
 Lanza completa hacia delante y hacia atras sin roces.
 Palas completamente abiertas y cerradas sin interferir.
 Amplificador de luz/fibra optica con cambio estable.
 Parametro Greifer S-Achse LichtSchranke guardado si se ha ajustado. De
 Limite S revisado y prueba con paquete correcta.

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
AVERIA 4 - Cambio de motores paso a paso antiguos a nuevos en ejes 
S, P y B
Averia anadida al documento base. Esta seccion esta pensada para que el tecnico vea rapidamente que motor tiene montado y 
que valores debe dejar en base de datos.
Captura de referencia: tabla ACHSPAR en IBExpert.
Objetivo
 Sustituir motor paso a paso antiguo por motor nuevo en S-Achse, P-Achse o B-Achse.
 Modificar solo los parametros del motor en la tabla ACHSPAR.
 Dejar el eje referenciado y probado en manual antes de produccion.
Regla rapida
 Tabla de base de datos: ACHSPAR.
 Campo para localizar el eje: Name.
 Ejes afectados: S-Achse, P-Achse y B-Achse.
 Parametros a cambiar: IncsPerStepN y Drehzahl.
 No tocar Zaehne, ZModul ni Getriebe en esta averia. Esos parametros pertenecen al cambio de correa/corona.
Tabla principal: modelo de motor y parametros
Modelo / tipo de motor Tabla Campo eje Parametro Valor que debe quedar
Motor paso a paso 
antiguo ACHSPAR Name IncsPerStepN 2
Motor paso a paso 
antiguo ACHSPAR Name Drehzahl 0
Motor nuevo 
HEDS-5540 Axx / 
WEDLS-HEDL-5541
ACHSPAR Name IncsPerStepN 2.5

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
Motor nuevo 
HEDS-5540 Axx / 
WEDLS-HEDL-5541
ACHSPAR Name Drehzahl 0
Lectura para el tecnico: si el eje lleva motor nuevo, dejar IncsPerStepN = 2.5 y Drehzahl = 0. Si se mantiene motor antiguo, dejar 
IncsPerStepN = 2 y Drehzahl = 0.
Aplicacion por eje
Eje fisico Nombre en base de datos Si monta motor nuevo Si monta motor antiguo
Eje S S-Achse IncsPerStepN = 2.5
Drehzahl = 0
IncsPerStepN = 2
Drehzahl = 0
Eje P P-Achse IncsPerStepN = 2.5
Drehzahl = 0
IncsPerStepN = 2
Drehzahl = 0
Eje B B-Achse IncsPerStepN = 2.5
Drehzahl = 0
IncsPerStepN = 2
Drehzahl = 0
Procedimiento simple
13. Identificar que eje se ha reparado: S, P o B.
14. Entrar en la tabla ACHSPAR.
15. Buscar el eje por el campo Name: S-Achse, P-Achse o B-Achse.
16. Comprobar que modelo de motor se ha montado.
17. Aplicar los valores de la tabla principal.
18. Guardar cambios.
19. Referenciar el eje y hacer prueba en manual a baja velocidad.
Consulta rapida de comprobacion
SELECT Name, IncsPerStepN, Drehzahl FROM Achspar WHERE Name IN (''S-Achse'', ''P-Achse'', ''B-Achse'');
Comprobacion final por eje
Eje Comprobacion fisica despues del cambio
S-Achse Mover lanza hacia delante y hacia atras. No debe perder pasos, 
golpear ni quedarse desplazada.
P-Achse Abrir y cerrar palas. Comprobar apertura real y ausencia de golpes 
con ventosa o cuernecillos.
B-Achse Mover el conjunto y comprobar que queda paralelo, sin roces ni 
saltos.
Captura de apoyo: pantalla Greifer para comprobar el movimiento en manual.
Criterio de cierre
 Los valores de ACHSPAR coinciden con el modelo de motor montado.
 El eje referencia correctamente.

Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
 El movimiento manual es suave y repetible.
 No aparecen golpes, saltos, perdida de pasos ni desplazamientos.
 Si el eje queda desajustado mecanicamente, volver a la Averia 1 para parametrizar limites y posiciones.
Uso interno - Verificar siempre en maquina antes de dejar en produccion','Guia_por_averias_orden_parametrizacion_S_B_P.pdf');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,1,'Averia Trabajo','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
GUIA TECNICA SIMPLE POR AVERIAS
Parametrizacion de ejes, cambio de correas, motores, cuernecillos, barrera de luz y ultrasonido
Criterio de esta version
Se han eliminado terminos confusos. Donde antes se decia "emulador", ahora se habla de amplificador de luz / amplificador de fibra 
optica. Cada averia empieza en pagina nueva y solo contiene lo necesario para ejecutarla.
Indice rapido
Averia Trabajo
1 Parametrizar conjuntamente los ejes P, S y B.
2 Cambiar correa/corona blanca 20 dientes <-> negra 16 dientes.
3 Cambio de cuernecillos + barrera de luz/amplificador de fibra optica + limite del eje S.
4 Cambio de motores paso a paso en ejes S, P y B.
5 Comprobacion y ajuste de ultrasonido.
Antes de tocar parametros
Anotar los valores actuales de la base de datos y de MACH4_Ctrl. Trabajar siempre en manual, con velocidad baja y comprobacion 
visual del conjunto.','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=1');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,2,'AVERIA 1 - Parametrizar conjuntamente los ejes P, S y B','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
AVERIA 1 - Parametrizar conjuntamente los ejes P, S y B
Imagen de apoyo: conjunto fisico de pinza y ejes P/S/B.
Captura de referencia: pantalla Greifer para mover ejes y leer valores.
Objetivo
 Dejar alineados S y B.
 Ajustar apertura real del eje P.
 Guardar limites AG+/KG+/AG-/KG- con valores practicos.
 Comprobar palas, lanza y ventosa sin roces ni golpes.
Parametrizacion ordenada por ejes
Orden de trabajo: comprobar primero S-Achse como referencia, despues ajustar B-Achse en funcion de S, y finalmente ajustar P-
Achse para la apertura real de palas.','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=2');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,3,'Página 3','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
Nota previa: comprobar primero el Nullpunkt del eje S. En sistemas normales debe estar en 135; en sistemas MP, S-Multipicking 
debe estar en 35; en sistemas nuevos, verificar si debe quedar a 0 antes de ajustar B.
1. S-Achse - comprobacion inicial, limites de lanza y barrera de luz
Parametro / punto Que hacer Valor / criterio
AG- Llevar S y B completos hacia atras. Leer valor 
Greifer del eje S. AG- = Greifer S + 1,5.
KG- Mismo punto fisico que AG-. KG- = Greifer S + 1,5.
Save_Pos Dejar posicion segura desde el limite trasero. Save_Pos = AG- + 1.
AG+ Llevar S y B completos hacia delante. Leer valor 
Greifer del eje S. AG+ = Greifer S - 1,5.
KG+ Limite positivo de seguridad del eje S. Despues 
comprobar barrera de luz. KG+ = 340 siempre.
Barrera de luz Comprobar que la senal cambia en el punto 
correcto. Parametro: Greifer S-Achse LichtSchranke.
2. B-Achse - alineacion del conjunto
Parametro / punto Que hacer Valor / criterio
Nullpunkt B Adelantar palas y ventosa hasta dejarlas paralelas. 
B se usa como referencia para alinear el conjunto. Eje S aprox. 135. S-Multipicking aprox. 35.
Correccion de Nullpunkt B Leer valor S y valor B. Calcular diferencia y corregir 
el Nullpunkt de B. X = S - B. Restar X al Nullpunkt de B.
AG- / KG- Con S y B completos hacia atras, ajustar limites 
traseros del eje B. Valor Greifer + 1,5. Save_Pos = AG- + 1.
AG+ / KG+ Con S y B completos hacia delante, ajustar limites 
delanteros del eje B.
Valor Greifer - 1,5. KG+ coherente con el limite 
delantero si aplica.
3. P-Achse - apertura real de palas
Parametro / punto Que hacer Valor / criterio
Nullpunkt P Medir con calibre de 60 mm. Poner palas a 60 mm y 
comprobar lectura Greifer.
Si Greifer no marca 60, corregir con + o - en 
Nullpunkt P.
AG- Ajustar minimo de trabajo de palas. AG- = 12. Si da problemas o choca con ventosa, 
usar 14.
KG- Ajustar minimo de seguridad de palas. KG- = 14.
Save_Pos Dejar posicion segura dentro del limite positivo 
usado. Save_Pos = 1 mm dentro de KG+ o AG+.
4. Prueba conjunta antes de cerrar
Eje / elemento Comprobacion fisica
S-Achse / lanza Llevar la lanza completa hacia delante y completa hacia atras. No debe golpear, 
forzar ni perder pasos.
S-Achse / barrera Tras KG+ = 340, comprobar que Greifer S-Achse LichtSchranke cambia en el 
punto correcto.
B-Achse Mover B junto con S hacia delante y hacia atras. Confirmar paralelo y sin roces.
P-Achse / palas Abrir palas completamente y cerrarlas completamente. Verificar 60 mm con 
calibre.
Ventosa Con palas adelantadas/cerradas, verificar que no choque con palas, cuernecillos 
ni zona de barrera.
Conjunto Repetir movimientos combinados S + B + P a baja velocidad antes de cerrar.
Criterio de cierre
La parametrizacion debe cerrarse eje por eje: primero S para confirmar la referencia del conjunto, despues B para dejarlo 
alineado en funcion de S, y finalmente P para apertura real de palas. No cerrar la averia hasta probar S + B + P combinados a 
baja velocidad, con lanza delante/atras y palas abiertas/cerradas.','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=3');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,4,'AVERIA 2 - Cambio de correa/corona blanca 20 <-> negra 16','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
AVERIA 2 - Cambio de correa/corona blanca 20 <-> negra 16
Captura de referencia: tabla ACHSPAR en IBExpert.
Trabajo fisico
1. Confirmar sentido del cambio: blanca 20 -> negra 16 o negra 16 -> blanca 20.
2. Parar maquina y trabajar en seguro.
3. Retirar correa/corona antigua.
4. Montar correa/corona nueva verificando asiento correcto en los dientes.
5. Comprobar tension: sin holgura excesiva y sin tensar de mas.
6. Mover manualmente el eje afectado y revisar que no haya saltos de dientes ni puntos duros.
Tabla ACHSPAR que se modifica
Eje Configuracion Zaehne ZModul Getriebe
S-Achse Blanca - 20 dientes 20 2.5 1.0
S-Achse Negra - 16 dientes 16 3.0 1.0
P-Achse Blanca - 20 dientes 20 5.0 1.0
P-Achse Negra - 16 dientes 16 6.0 1.0
B-Achse Blanca - 20 dientes 20 2.5 1.0
B-Achse Negra - 16 dientes 16 3.0 1.0
Ejes que no se tocan por este cambio
Para el cambio 20 <-> 16 solo se modifican S-Achse, P-Achse y B-Achse. No modificar C-Achse ni D-Achse por esta averia.','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=4');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,5,'Página 5','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
Comprobacion final
 Guardar cambios.
 Recargar parametros o reiniciar control si procede.
 Referenciar ejes.
 Mover eje a baja velocidad.
 Comprobar palas abiertas/cerradas y lanza adelante/atras.
 Realizar prueba con paquete.','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=5');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,6,'AVERIA 3 - Cambio de cuernecillos + barrera de luz/amplificador +','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
AVERIA 3 - Cambio de cuernecillos + barrera de luz/amplificador + 
limite del eje S
Captura de referencia: pantalla Greifer para mover S y comprobar senal de barrera de luz.
Objetivo
 Cambiar cuernecillos.
 Comprobar que no hay roces con palas, lanza ni ventosa.
 Configurar/verificar barrera de luz con el amplificador de luz o fibra optica.
 Comprobar el limite del eje S despues del ajuste.
Cambio fisico de cuernecillos
7. Parar maquina y trabajar en seguro.
8. Retirar cuernecillos antiguos.
9. Limpiar apoyo y revisar rebabas, deformaciones o restos.
10. Montar cuernecillos nuevos en la misma orientacion.
11. Apretar sin deformar la pieza.
12. Mover manualmente palas y lanza para verificar que no roza ni tapa la barrera.
Fijacion tras ajuste
Cuando el ajuste quede validado, aplicar esmalte de unas en el punto de fijacion/tornilleria para dejar marcada y fijada la posicion.
Barrera de luz: parametro real en base de datos
Elemento Nombre a usar en la guia
Parametro Greifer S-Achse LichtSchranke
Metodo Mover eje S en Greifer hasta encontrar el ultimo valor que enciende la barrera. Guardar ese 
valor - 1 toque/paso.
Comprobacion Avanzar y retroceder varias veces. La senal debe cambiar siempre en el mismo punto.
Amplificador de luz / fibra optica
 No llamarlo emulador en la guia.
 Comprobar en el amplificador que la senal cambia de libre a cortada de forma estable.
 Si el amplificador cambia pero MACH4_Ctrl no cambia, revisar entrada, cableado o comunicacion con el control.','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=6');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,7,'Página 7','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
 Si MACH4_Ctrl cambia pero fisicamente falla la deteccion, revisar alineacion, fibra, suciedad, cuernecillos o distancia.
Comprobacion del limite del eje S
Paso Comprobacion
1 Llevar S hacia la zona de barrera lentamente.
2 Confirmar que la barrera se enciende antes de que haya golpe o roce.
3 Confirmar que los cuernecillos no tapan la barrera fuera de tiempo.
4 Verificar KG+ del eje S = 340 cuando aplique.
5 Repetir con palas abiertas y cerradas.
Prueba final de la averia
 Cuernecillos firmes, alineados y fijados con esmalte tras validar.
 Lanza completa hacia delante y hacia atras sin roces.
 Palas completamente abiertas y cerradas sin interferir.
 Amplificador de luz/fibra optica con cambio estable.
 Parametro Greifer S-Achse LichtSchranke guardado si se ha ajustado. De
 Limite S revisado y prueba con paquete correcta.','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=7');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,8,'Página 8','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=8');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,9,'AVERIA 4 - Cambio de motores paso a paso antiguos a nuevos en ejes','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
AVERIA 4 - Cambio de motores paso a paso antiguos a nuevos en ejes 
S, P y B
Averia anadida al documento base. Esta seccion esta pensada para que el tecnico vea rapidamente que motor tiene montado y 
que valores debe dejar en base de datos.
Captura de referencia: tabla ACHSPAR en IBExpert.
Objetivo
 Sustituir motor paso a paso antiguo por motor nuevo en S-Achse, P-Achse o B-Achse.
 Modificar solo los parametros del motor en la tabla ACHSPAR.
 Dejar el eje referenciado y probado en manual antes de produccion.
Regla rapida
 Tabla de base de datos: ACHSPAR.
 Campo para localizar el eje: Name.
 Ejes afectados: S-Achse, P-Achse y B-Achse.
 Parametros a cambiar: IncsPerStepN y Drehzahl.
 No tocar Zaehne, ZModul ni Getriebe en esta averia. Esos parametros pertenecen al cambio de correa/corona.
Tabla principal: modelo de motor y parametros
Modelo / tipo de motor Tabla Campo eje Parametro Valor que debe quedar
Motor paso a paso 
antiguo ACHSPAR Name IncsPerStepN 2
Motor paso a paso 
antiguo ACHSPAR Name Drehzahl 0
Motor nuevo 
HEDS-5540 Axx / 
WEDLS-HEDL-5541
ACHSPAR Name IncsPerStepN 2.5','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=9');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,10,'Página 10','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
Motor nuevo 
HEDS-5540 Axx / 
WEDLS-HEDL-5541
ACHSPAR Name Drehzahl 0
Lectura para el tecnico: si el eje lleva motor nuevo, dejar IncsPerStepN = 2.5 y Drehzahl = 0. Si se mantiene motor antiguo, dejar 
IncsPerStepN = 2 y Drehzahl = 0.
Aplicacion por eje
Eje fisico Nombre en base de datos Si monta motor nuevo Si monta motor antiguo
Eje S S-Achse IncsPerStepN = 2.5
Drehzahl = 0
IncsPerStepN = 2
Drehzahl = 0
Eje P P-Achse IncsPerStepN = 2.5
Drehzahl = 0
IncsPerStepN = 2
Drehzahl = 0
Eje B B-Achse IncsPerStepN = 2.5
Drehzahl = 0
IncsPerStepN = 2
Drehzahl = 0
Procedimiento simple
13. Identificar que eje se ha reparado: S, P o B.
14. Entrar en la tabla ACHSPAR.
15. Buscar el eje por el campo Name: S-Achse, P-Achse o B-Achse.
16. Comprobar que modelo de motor se ha montado.
17. Aplicar los valores de la tabla principal.
18. Guardar cambios.
19. Referenciar el eje y hacer prueba en manual a baja velocidad.
Consulta rapida de comprobacion
SELECT Name, IncsPerStepN, Drehzahl FROM Achspar WHERE Name IN (''S-Achse'', ''P-Achse'', ''B-Achse'');
Comprobacion final por eje
Eje Comprobacion fisica despues del cambio
S-Achse Mover lanza hacia delante y hacia atras. No debe perder pasos, 
golpear ni quedarse desplazada.
P-Achse Abrir y cerrar palas. Comprobar apertura real y ausencia de golpes 
con ventosa o cuernecillos.
B-Achse Mover el conjunto y comprobar que queda paralelo, sin roces ni 
saltos.
Captura de apoyo: pantalla Greifer para comprobar el movimiento en manual.
Criterio de cierre
 Los valores de ACHSPAR coinciden con el modelo de motor montado.
 El eje referencia correctamente.','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=10');
INSERT INTO manual_chunks(manual_id,page_number,section,content,source) VALUES (1,11,'Página 11','Guia tecnica por averias - Ejes P/S/B, correas, motores, cuernecillos y barrera de luz
Uso interno - Verificar siempre en maquina antes de dejar en produccion
 El movimiento manual es suave y repetible.
 No aparecen golpes, saltos, perdida de pasos ni desplazamientos.
 Si el eje queda desajustado mecanicamente, volver a la Averia 1 para parametrizar limites y posiciones.
Uso interno - Verificar siempre en maquina antes de dejar en produccion','Guia_por_averias_orden_parametrizacion_S_B_P.pdf#page=11');
