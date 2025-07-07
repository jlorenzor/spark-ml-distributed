# FASE 3: Selección y Preparación de Dataset

## **ESTRUCTURA ADICIONAL DEL REPOSITORIO**

```
spark-hadoop-cluster/
├── phase3/
│   ├── find-dataset.sh
│   ├── download-dataset.sh
│   ├── analyze-dataset.py
│   ├── load-to-hdfs.sh
│   ├── explore-data.scala
│   └── datasets/
│       └── README.md
└── docs/
    ├── dataset-research.md
    └── dataset-analysis.md
```

---

## **1. phase3/find-dataset.sh**

```bash
#!/bin/bash

echo "=== BÚSQUEDA DE DATASETS EN PNDA ==="
echo "Plataforma Nacional de Datos Abiertos del Perú"
echo "URL: https://www.datosabiertos.gob.pe/"
echo

echo "Categorías sugeridas para el proyecto:"
echo "1. SALUD/MEDICINA:"
echo "   - Vacunación COVID-19"
echo "   - Indicadores de salud materna"
echo "   - Defunciones por causa"
echo "   - Establecimientos de salud"
echo "   - Casos de enfermedades"
echo

echo "2. AGRICULTURA:"
echo "   - Producción agrícola por regiones"
echo "   - Precios de productos agrícolas"
echo "   - Superficie cultivada"
echo "   - Rendimiento de cultivos"
echo "   - Exportaciones agrícolas"
echo

echo "=== CRITERIOS DE SELECCIÓN ==="
echo "✓ Dataset NO usado en evaluaciones anteriores"
echo "✓ Formato CSV con campos decimales/numéricos"
echo "✓ Fecha de publicación reciente (2023-2024)"
echo "✓ Tamaño adecuado para análisis (1000+ registros)"
echo "✓ Estructura clara con metadatos"
echo

echo "=== INVESTIGACIÓN REQUERIDA ==="
echo "1. Documentar fuente y fecha de publicación"
echo "2. Buscar investigaciones previas sobre el dataset"
echo "3. Buscar artículos científicos que lo utilicen"
echo "4. Analizar estructura y campos disponibles"
echo

echo "Ejecuta: ./download-dataset.sh [URL_DATASET] para descargar"
```

---

## **2. phase3/download-dataset.sh**

```bash
#!/bin/bash

DATASET_URL=$1
DATASET_NAME=$2

if [ -z "$DATASET_URL" ] || [ -z "$DATASET_NAME" ]; then
    echo "Uso: $0 <URL_DATASET> <NOMBRE_DATASET>"
    echo "Ejemplo: $0 'https://www.datosabiertos.gob.pe/dataset/...' 'produccion_agricola'"
    exit 1
fi

echo "=== DESCARGANDO DATASET: $DATASET_NAME ==="

# Crear directorio para datasets
mkdir -p ~/datasets/raw
mkdir -p ~/datasets/processed
cd ~/datasets/raw

# Descargar dataset
echo "Descargando desde: $DATASET_URL"
wget -O "${DATASET_NAME}.csv" "$DATASET_URL"

if [ $? -eq 0 ]; then
    echo "✓ Dataset descargado: ${DATASET_NAME}.csv"
    
    # Información básica del archivo
    echo
    echo "=== INFORMACIÓN DEL DATASET ==="
    echo "Tamaño: $(du -h ${DATASET_NAME}.csv | cut -f1)"
    echo "Líneas: $(wc -l < ${DATASET_NAME}.csv)"
    echo
    echo "Primeras 5 líneas:"
    head -5 "${DATASET_NAME}.csv"
    echo
    echo "Últimas 5 líneas:"
    tail -5 "${DATASET_NAME}.csv"
    
    # Documentar metadatos
    echo "=== DOCUMENTANDO METADATOS ==="
    cat > "../${DATASET_NAME}_metadata.txt" << EOF
Dataset: $DATASET_NAME
URL: $DATASET_URL
Fecha de descarga: $(date)
Tamaño: $(du -h ${DATASET_NAME}.csv | cut -f1)
Número de registros: $(wc -l < ${DATASET_NAME}.csv)
Encoding: $(file -i ${DATASET_NAME}.csv)

=== ESTRUCTURA DEL DATASET ===
$(head -1 ${DATASET_NAME}.csv)

=== MUESTRA DE DATOS ===
$(head -10 ${DATASET_NAME}.csv)
EOF
    
    echo "✓ Metadatos guardados en: ../${DATASET_NAME}_metadata.txt"
    echo
    echo "Siguiente paso: Ejecutar ./analyze-dataset.py ${DATASET_NAME}.csv"
    
else
    echo "✗ Error al descargar el dataset"
    exit 1
fi
```

---

## **3. phase3/analyze-dataset.py**

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np
import sys
import os
from datetime import datetime

def analyze_dataset(csv_file):
    """Analiza estructura y características del dataset"""
    
    print("=== ANÁLISIS EXPLORATORIO DEL DATASET ===")
    print(f"Archivo: {csv_file}")
    print(f"Fecha de análisis: {datetime.now()}")
    print()
    
    try:
        # Leer dataset con diferentes encodings
        encodings = ['utf-8', 'latin-1', 'cp1252', 'iso-8859-1']
        df = None
        
        for encoding in encodings:
            try:
                df = pd.read_csv(csv_file, encoding=encoding)
                print(f"✓ Dataset leído con encoding: {encoding}")
                break
            except:
                continue
        
        if df is None:
            print("✗ Error: No se pudo leer el dataset con ningún encoding")
            return
        
        # Información general
        print("\n=== INFORMACIÓN GENERAL ===")
        print(f"Dimensiones: {df.shape[0]} filas × {df.shape[1]} columnas")
        print(f"Memoria utilizada: {df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
        
        # Tipos de datos
        print("\n=== TIPOS DE DATOS ===")
        print(df.dtypes)
        
        # Campos numéricos/decimales (importantes para ML)
        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        print(f"\n=== CAMPOS NUMÉRICOS ({len(numeric_cols)}) ===")
        for col in numeric_cols:
            print(f"- {col}: {df[col].dtype}")
        
        # Valores faltantes
        print("\n=== VALORES FALTANTES ===")
        missing = df.isnull().sum()
        missing_pct = (missing / len(df)) * 100
        missing_df = pd.DataFrame({
            'Columna': missing.index,
            'Valores_Faltantes': missing.values,
            'Porcentaje': missing_pct.values
        })
        print(missing_df[missing_df['Valores_Faltantes'] > 0])
        
        # Estadísticas descriptivas para campos numéricos
        if len(numeric_cols) > 0:
            print("\n=== ESTADÍSTICAS DESCRIPTIVAS ===")
            print(df[numeric_cols].describe())
        
        # Muestra de datos
        print("\n=== MUESTRA DE DATOS (5 registros) ===")
        print(df.head())
        
        # Identificar campos para algoritmos ML
        print("\n=== ANÁLISIS PARA MACHINE LEARNING ===")
        
        # Campos para clasificación (categóricos)
        categorical_cols = df.select_dtypes(include=['object']).columns.tolist()
        print(f"Campos categóricos (candidatos para target de clasificación): {len(categorical_cols)}")
        for col in categorical_cols[:5]:  # Mostrar solo los primeros 5
            unique_values = df[col].nunique()
            print(f"- {col}: {unique_values} valores únicos")
        
        # Campos para regresión (numéricos continuos)
        float_cols = df.select_dtypes(include=['float64', 'float32']).columns.tolist()
        print(f"\nCampos decimales (candidatos para target de regresión): {len(float_cols)}")
        for col in float_cols:
            print(f"- {col}: rango [{df[col].min():.2f}, {df[col].max():.2f}]")
        
        # Recomendaciones
        print("\n=== RECOMENDACIONES PARA CONSULTAS SPARK ===")
        
        if len(numeric_cols) >= 3:
            print("✓ Dataset adecuado para consultas complejas con MapReduce")
            print("✓ Suficientes campos numéricos para agregaciones")
        else:
            print("⚠ Pocos campos numéricos. Considerar transformaciones.")
        
        if len(float_cols) > 0:
            print("✓ Dataset adecuado para DecisionTreeRegressor")
            target_regression = float_cols[0]
            print(f"  - Target sugerido para regresión: {target_regression}")
        
        if len(categorical_cols) > 0:
            print("✓ Dataset adecuado para MultilayerPerceptronClassifier")
            target_classification = categorical_cols[0]
            print(f"  - Target sugerido para clasificación: {target_classification}")
        
        # Guardar reporte
        dataset_name = os.path.splitext(os.path.basename(csv_file))[0]
        report_file = f"../processed/{dataset_name}_analysis_report.txt"
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(f"REPORTE DE ANÁLISIS - {dataset_name}\n")
            f.write(f"Generado: {datetime.now()}\n")
            f.write(f"Dimensiones: {df.shape[0]} × {df.shape[1]}\n")
            f.write(f"Campos numéricos: {len(numeric_cols)}\n")
            f.write(f"Campos categóricos: {len(categorical_cols)}\n")
            f.write(f"Campos decimales: {len(float_cols)}\n")
            f.write(f"Valores faltantes: {missing.sum()}\n\n")
            f.write("CAMPOS NUMÉRICOS:\n")
            for col in numeric_cols:
                f.write(f"- {col}\n")
            f.write("\nCAMPOS CATEGÓRICOS:\n")
            for col in categorical_cols:
                f.write(f"- {col}\n")
        
        print(f"\n✓ Reporte guardado en: {report_file}")
        
        # Preparar datos limpios para HDFS
        print("\n=== PREPARANDO DATOS PARA HDFS ===")
        
        # Limpiar datos básicos
        df_clean = df.copy()
        
        # Remover filas completamente vacías
        df_clean = df_clean.dropna(how='all')
        
        # Para campos numéricos, llenar NaN con 0 o media
        for col in numeric_cols:
            if df_clean[col].isnull().sum() > 0:
                df_clean[col] = df_clean[col].fillna(df_clean[col].mean())
        
        # Para campos categóricos, llenar con 'Unknown'
        for col in categorical_cols:
            if df_clean[col].isnull().sum() > 0:
                df_clean[col] = df_clean[col].fillna('Unknown')
        
        # Guardar datos limpios
        clean_file = f"../processed/{dataset_name}_clean.csv"
        df_clean.to_csv(clean_file, index=False, encoding='utf-8')
        
        print(f"✓ Datos limpios guardados: {clean_file}")
        print(f"  - Registros originales: {len(df)}")
        print(f"  - Registros limpios: {len(df_clean)}")
        
        print("\nSiguiente paso: ./load-to-hdfs.sh")
        
    except Exception as e:
        print(f"✗ Error en el análisis: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python3 analyze-dataset.py <archivo.csv>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    if not os.path.exists(csv_file):
        print(f"Error: El archivo {csv_file} no existe")
        sys.exit(1)
    
    analyze_dataset(csv_file)
```

---

## **4. phase3/load-to-hdfs.sh**

```bash
#!/bin/bash

DATASET_NAME=$1

if [ -z "$DATASET_NAME" ]; then
    echo "Uso: $0 <NOMBRE_DATASET>"
    echo "Ejemplo: $0 produccion_agricola"
    exit 1
fi

echo "=== CARGANDO DATASET A HDFS ==="

# Verificar que HDFS esté ejecutándose
if ! hdfs dfs -ls / > /dev/null 2>&1; then
    echo "✗ Error: HDFS no está ejecutándose"
    echo "Ejecuta: cd ~/cluster-setup && ./scripts/start-cluster.sh"
    exit 1
fi

# Crear directorios en HDFS
echo "Creando directorios en HDFS..."
hdfs dfs -mkdir -p /datasets/raw
hdfs dfs -mkdir -p /datasets/processed
hdfs dfs -mkdir -p /datasets/results

# Cargar datos raw
echo "Cargando datos originales..."
if [ -f "~/datasets/raw/${DATASET_NAME}.csv" ]; then
    hdfs dfs -put ~/datasets/raw/${DATASET_NAME}.csv /datasets/raw/
    echo "✓ Datos raw cargados a HDFS: /datasets/raw/${DATASET_NAME}.csv"
fi

# Cargar datos limpios
echo "Cargando datos limpios..."
if [ -f "~/datasets/processed/${DATASET_NAME}_clean.csv" ]; then
    hdfs dfs -put ~/datasets/processed/${DATASET_NAME}_clean.csv /datasets/processed/
    echo "✓ Datos limpios cargados a HDFS: /datasets/processed/${DATASET_NAME}_clean.csv"
fi

# Verificar carga
echo
echo "=== VERIFICACIÓN DE CARGA EN HDFS ==="
echo "Archivos en /datasets:"
hdfs dfs -ls -h /datasets/raw/
hdfs dfs -ls -h /datasets/processed/

echo
echo "Información del archivo principal:"
hdfs dfs -stat "Tamaño: %b bytes, Modificado: %y" /datasets/processed/${DATASET_NAME}_clean.csv

echo
echo "Primeras líneas del dataset en HDFS:"
hdfs dfs -cat /datasets/processed/${DATASET_NAME}_clean.csv | head -5

echo
echo "✓ Dataset cargado correctamente en HDFS"
echo "Siguiente paso: spark-shell --master spark://spark-master:7077"
echo "Luego ejecutar: :load explore-data.scala"
```

---

## **5. phase3/explore-data.scala**

```scala
// Exploración inicial del dataset con Spark
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

// Configurar sesión Spark
val spark = SparkSession.builder()
  .appName("Dataset Exploration")
  .config("spark.sql.adaptive.enabled", "true")
  .config("spark.sql.adaptive.coalescePartitions.enabled", "true")
  .getOrCreate()

import spark.implicits._

// Cargar dataset desde HDFS
// CAMBIAR: Reemplazar "DATASET_NAME" por el nombre real de tu dataset
val datasetName = "DATASET_NAME"  // ← CAMBIAR AQUÍ
val df = spark.read
  .option("header", "true")
  .option("inferSchema", "true")
  .csv(s"hdfs://spark-master:9000/datasets/processed/${datasetName}_clean.csv")

println("=== INFORMACIÓN BÁSICA DEL DATASET ===")
println(s"Número de registros: ${df.count()}")
println(s"Número de columnas: ${df.columns.length}")
println(s"Particiones: ${df.rdd.getNumPartitions}")

println("\n=== ESQUEMA DEL DATASET ===")
df.printSchema()

println("\n=== PRIMEROS 10 REGISTROS ===")
df.show(10)

println("\n=== ESTADÍSTICAS DESCRIPTIVAS ===")
df.describe().show()

// Identificar campos numéricos
val numericCols = df.dtypes.filter(_._2 != "StringType").map(_._1)
println(s"\n=== CAMPOS NUMÉRICOS (${numericCols.length}) ===")
numericCols.foreach(println)

// Identificar campos categóricos
val categoricalCols = df.dtypes.filter(_._2 == "StringType").map(_._1)
println(s"\n=== CAMPOS CATEGÓRICOS (${categoricalCols.length}) ===")
categoricalCols.foreach(println)

// Análisis de valores únicos para campos categóricos
println("\n=== VALORES ÚNICOS EN CAMPOS CATEGÓRICOS ===")
categoricalCols.take(5).foreach { col =>
  val uniqueCount = df.select(col).distinct().count()
  println(s"$col: $uniqueCount valores únicos")
  
  if (uniqueCount <= 20) {
    println("Valores:")
    df.select(col).distinct().orderBy(col).show(20, false)
  }
}

// Análisis de correlaciones para campos numéricos
if (numericCols.length >= 2) {
  println("\n=== CORRELACIONES ENTRE CAMPOS NUMÉRICOS ===")
  val assembler = new org.apache.spark.ml.feature.VectorAssembler()
    .setInputCols(numericCols)
    .setOutputCol("features")
  
  val assembled = assembler.transform(df)
  
  // Calcular correlaciones
  import org.apache.spark.ml.stat.Correlation
  val correlations = Correlation.corr(assembled, "features").head
  println(s"Matriz de correlaciones calculada: ${correlations.getAs[org.apache.spark.ml.linalg.Matrix](0)}")
}

// Guardar información del dataset
val datasetInfo = s"""
=== INFORMACIÓN DEL DATASET: $datasetName ===
Registros: ${df.count()}
Columnas: ${df.columns.length}
Particiones: ${df.rdd.getNumPartitions}

Campos numéricos: ${numericCols.mkString(", ")}
Campos categóricos: ${categoricalCols.mkString(", ")}

Generado: ${java.time.LocalDateTime.now()}
"""

// Guardar en HDFS
import java.io.PrintWriter
val infoPath = s"/tmp/dataset_info_${datasetName}.txt"
new PrintWriter(infoPath) {
  write(datasetInfo)
  close()
}

// Subir a HDFS
import sys.process._
s"hdfs dfs -put $infoPath /datasets/processed/" !

println(s"\n✓ Información guardada en HDFS: /datasets/processed/dataset_info_${datasetName}.txt")

println("\n=== EXPLORACIÓN COMPLETADA ===")
println("El dataset está listo para las consultas complejas de la Fase 4")
println("\nSugerencias para consultas:")
println("1. Agregaciones complejas con groupBy y múltiples métricas")
println("2. Joins entre particiones del mismo dataset")
println("3. Window functions para análisis temporales")
println("4. Machine Learning con campos identificados")

// Ejemplo de consulta compleja (comentado)
/*
println("\n=== EJEMPLO DE CONSULTA COMPLEJA ===")
// Descomentar y adaptar según tu dataset:

val complexQuery = df
  .groupBy("CAMPO_CATEGORICO")  // Cambiar por campo real
  .agg(
    avg("CAMPO_NUMERICO_1").alias("promedio_1"),      // Cambiar por campo real
    sum("CAMPO_NUMERICO_2").alias("suma_2"),          // Cambiar por campo real
    count("*").alias("total_registros"),
    stddev("CAMPO_NUMERICO_1").alias("desviacion_std")
  )
  .orderBy(desc("promedio_1"))

complexQuery.show()
*/
```

---

## **6. docs/dataset-research.md**

```markdown
# Investigación del Dataset

## Información Básica
- **Nombre del Dataset**: [COMPLETAR]
- **Fuente**: Plataforma Nacional de Datos Abiertos (PNDA)
- **URL**: [COMPLETAR]
- **Fecha de Publicación**: [COMPLETAR]
- **Última Actualización**: [COMPLETAR]
- **Formato**: CSV
- **Licencia**: [COMPLETAR]

## Descripción del Dataset
[Describir qué contiene el dataset, su propósito y contexto]

## Metadatos
- **Número de registros**: [COMPLETAR]
- **Número de campos**: [COMPLETAR]
- **Tamaño del archivo**: [COMPLETAR]
- **Encoding**: [COMPLETAR]
- **Separador**: [COMPLETAR]

## Estructura de Datos

### Campos Numéricos
| Campo | Tipo | Descripción | Rango |
|-------|------|-------------|-------|
| [CAMPO1] | Float | [DESCRIPCIÓN] | [MIN - MAX] |
| [CAMPO2] | Integer | [DESCRIPCIÓN] | [MIN - MAX] |

### Campos Categóricos
| Campo | Tipo | Descripción | Valores Únicos |
|-------|------|-------------|----------------|
| [CAMPO1] | String | [DESCRIPCIÓN] | [NÚMERO] |
| [CAMPO2] | String | [DESCRIPCIÓN] | [NÚMERO] |

## Investigaciones Previas

### Artículos Académicos
1. **Título**: [TÍTULO DEL ARTÍCULO]
   - **Autores**: [AUTORES]
   - **Año**: [AÑO]
   - **Revista/Conferencia**: [PUBLICACIÓN]
   - **DOI/URL**: [ENLACE]
   - **Resumen**: [BREVE DESCRIPCIÓN DE CÓMO USARON EL DATASET]

2. **Título**: [TÍTULO DEL ARTÍCULO]
   - **Autores**: [AUTORES]
   - **Año**: [AÑO]
   - **Revista/Conferencia**: [PUBLICACIÓN]
   - **DOI/URL**: [ENLACE]
   - **Resumen**: [BREVE DESCRIPCIÓN]

### Informes Técnicos
1. **Título**: [TÍTULO DEL INFORME]
   - **Institución**: [ORGANIZACIÓN]
   - **Año**: [AÑO]
   - **URL**: [ENLACE]
   - **Resumen**: [DESCRIPCIÓN]

### Otros Usos Documentados
- [LISTAR OTROS PROYECTOS O ANÁLISIS QUE HAYAN UTILIZADO ESTE DATASET]

## Calidad de los Datos

### Valores Faltantes
- **Campos con valores faltantes**: [LISTAR]
- **Porcentaje de completitud**: [PORCENTAJE]

### Consistencia
- **Duplicados detectados**: [SÍ/NO - CANTIDAD]
- **Inconsistencias**: [DESCRIBIR]

### Outliers
- **Campos con outliers**: [LISTAR]
- **Método de detección**: [DESCRIBIR]

## Relevancia para el Proyecto

### Idoneidad para Machine Learning
- **MultilayerPerceptronClassifier**: 
  - Campo target: [CAMPO]
  - Features: [LISTAR CAMPOS]
  - Justificación: [EXPLICAR]

- **DecisionTreeRegressor**:
  - Campo target: [CAMPO]
  - Features: [LISTAR CAMPOS]
  - Justificación: [EXPLICAR]

### Complejidad para MapReduce
- **Consultas complejas posibles**: [DESCRIBIR]
- **Campos para agregaciones**: [LISTAR]
- **Joins internos posibles**: [DESCRIBIR]

## Referencias
1. [REFERENCIA 1]
2. [REFERENCIA 2]
3. [REFERENCIA 3]

---
*Documento actualizado el: [FECHA]*
```

---

## **INSTRUCCIONES DE USO - FASE 3**

### 1. Agregar archivos al repositorio GitHub
Sube todos los archivos de `phase3/` a tu repositorio existente.

### 2. En la VM Master, descargar scripts de Fase 3:
```bash
cd ~/cluster-setup
wget https://raw.githubusercontent.com/TU-USUARIO/spark-hadoop-cluster/main/phase3/find-dataset.sh
wget https://raw.githubusercontent.com/TU-USUARIO/spark-hadoop-cluster/main/phase3/download-dataset.sh
wget https://raw.githubusercontent.com/TU-USUARIO/spark-hadoop-cluster/main/phase3/analyze-dataset.py
wget https://raw.githubusercontent.com/TU-USUARIO/spark-hadoop-cluster/main/phase3/load-to-hdfs.sh
wget https://raw.githubusercontent.com/TU-USUARIO/spark-hadoop-cluster/main/phase3/explore-data.scala
chmod +x *.sh
```

### 3. Ejecutar secuencia de comandos:
```bash
# 1. Investigar opciones de datasets
./find-dataset.sh

# 2. Descargar dataset seleccionado
./download-dataset.sh "URL_DEL_DATASET" "nombre_dataset"

# 3. Analizar estructura del dataset
python3 analyze-dataset.py ~/datasets/raw/nombre_dataset.csv

# 4. Cargar a HDFS
./load-to-hdfs.sh nombre_dataset

# 5. Explorar con Spark
spark-shell --master spark://spark-master:7077
# Dentro de spark-shell:
:load explore-data.scala
```

### 4. Completar documentación
Editar el archivo `docs/dataset-research.md` con la información específica de tu dataset seleccionado.

**La FASE 3 está lista para automatizar la selección y preparación de datos! 🚀**