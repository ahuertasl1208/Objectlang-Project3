# Corpus de aceptacion para el checker de ObjectLang (bloque 6)

- `ok/`: programas que deben producir **cero errores estaticos**.
- `err/`: programas sintacticamente validos que deben producir **al menos un error estatico**.
- La primera linea de cada archivo `err` documenta el diagnostico esperado.
- Ejecutar cada archivo con `runObjectlang(|file:///ruta/absoluta/archivo.ol|)` desde `Main.rsc`.
- Mientras `Checker.rsc` sea un stub, los casos `err` pueden no fallar. No implica que sean correctos.

Validacion por etapas:
1. Parsear todos los archivos: no deben producir `ParseError`.
2. Implementar las reglas: `ok` sin errores y `err` con errores.
3. Comprobar que el diagnostico corresponde a la primera linea, no a un fallo incidental.

Los casos de `ok` 05 y 06 requieren comprobar ademas las reglas de genericos y metodos.
