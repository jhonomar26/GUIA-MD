# Requerimiento: configuración de documentos contables igual a crédito

## Pedido original

> lo que necesitamos es replicar lo que ya existe en D:\rep1\SIIAN\PruebaPostgreSQL\Views\DocumentoCredito\Index.cshtml para contabilidad o el modulo de contabilidad, desde la base de datos vamos a armar el plan con powerskills, el plan consta de fases

## Indagación

**P: Contabilidad ya tiene agrupaciones, tipos de documento y combos (se construyeron con el expediente virtual contable). ¿Se construye algo aparte o se ajusta lo que ya existe?**
R: "si existen, pero la idea es replicar lo que ya existe en credito". Se ajusta lo existente hasta igualar crédito.

**P: ¿Alcance: solo la pantalla de configuración, o también que la carga de documentos contables use las banderas nuevas (firma, foto, geolocalización, vencimiento)?**
R: "si la idea es replicar lo que esta en creditos nada mas para esto". Solo la configuración.

**P: De lo que tiene crédito, ¿qué aplica en contabilidad?** (preguntas P1 a P6 del [`ANALISIS.md`](./ANALISIS.md))
R: "la idea por ahora es solo centrarnos en esta vista":
- **Tipos de soporte:** se quita la grilla de tipos de soporte.
- **Se replican:** "para firmar" en combos, formatos personalizados, firma electrónica y foto.
- **Inactivar en vez de borrar:** sí.
- **Mismo documento dos veces en un combo:** se impide.
- **No se replican:** "para convenios", "días de fin de crédito" y geolocalización.

**P: ¿Cómo se maneja "para firmar" sin convenios, y qué plantillas se ofrecen en formatos?**
R: Para firmar: "el mismo manejo que ya se hace en crédito". Formatos: "b me parece mejor, pero por ahora solo nos vamos a centrar aquí". Se crea una marca nueva de "formato contable", pero sin tocar la pantalla de formatos.

**P: Con "inactivar en vez de borrar", ¿los inactivos se dejan de pedir en los comprobantes?**
R: "la idea en esencia es replicar la forma en como funciona para credito en contabilidad, eso como tal". Sí, igual que crédito: solo combos activos, y solo documentos activos del combo.

**Pendiente:** no quedó claro a qué se refiere "powerskills" en el pedido.

## Regla de negocio resuelta

- La configuración de documentos contables debe ofrecer lo mismo que la de crédito, salvo convenios, días de fin de crédito y geolocalización.
- Solo esta vista. El uso en la carga de documentos a comprobantes queda para después.
- Se trabaja desde la base de datos hacia la pantalla, por fases (`PLAN.md`, después del análisis).
