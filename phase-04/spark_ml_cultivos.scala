// ===================================================================
// ANÁLISIS DE CULTIVOS REGISTRADOS EN PIURA CON APACHE SPARK
// CC531 A - Análisis en Macrodatos
// Autores:
// * Gladys Alesandra Yagi V´asquez
// * Jhonny Stuart Lorenzo Rojas
// Versiones usadas:
// * Spark 3.0.1
// * Scala 2.12.10
// * Hadoop 3.2.1
// ===================================================================

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import org.apache.spark.ml.classification.MultilayerPerceptronClassifier
import org.apache.spark.ml.regression.DecisionTreeRegressor
import org.apache.spark.ml.feature.{VectorAssembler, StandardScaler, StringIndexer}
import org.apache.spark.ml.evaluation.{BinaryClassificationEvaluator, RegressionEvaluator, MulticlassClassificationEvaluator}
import org.apache.spark.ml.Pipeline
import org.apache.spark.storage.StorageLevel
import scala.collection.mutable.ArrayBuffer
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

object AnalisisAgricolaPeruSpark {

  def main(args: Array[String]): Unit = {
    
    // ===================================================================
    // 1. CONFIGURACIÓN INICIAL DEL SPARK SESSION
    // ===================================================================
    
    val spark = SparkSession.builder()
      .appName("Analisis Agricola Peru - CC531")
      .config("spark.sql.adaptive.enabled", "true")
      .config("spark.sql.adaptive.coalescePartitions.enabled", "true")
      .config("spark.sql.adaptive.skewJoin.enabled", "true")
      .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
      .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")
    
    import spark.implicits._
    
    println("=== INICIANDO ANÁLISIS DE DATOS AGRÍCOLAS DEL PERÚ ===")
    println(s"Spark Version: ${spark.version}")
    println(s"Scala Version: ${scala.util.Properties.versionString}")
    println(s"Timestamp: ${LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)}")
    
    // ===================================================================
    // 2. CARGA Y LIMPIEZA DE DATOS DESDE HDFS
    // ===================================================================
    
    val tiempoInicio = System.currentTimeMillis()
    
    println("\n=== CARGANDO DATOS DESDE HDFS ===")
    
    // Cargar datos desde HDFS
    val rutaHDFS = "hdfs://spark-master:9000/user/nodo/cultivos.csv"
    
    val dfRaw = spark.read
      .option("header", "true")
      .option("inferSchema", "true")
      .csv(rutaHDFS)
    
    println(s"Registros cargados: ${dfRaw.count()}")
    println("Esquema del dataset:")
    dfRaw.printSchema()
    
    // Limpieza y transformación de datos
    val df = dfRaw
      .filter($"PRODUCCION".isNotNull && $"PRECIO_CHACRA".isNotNull)
      .filter($"SIEMBRA".isNotNull && $"COSECHA".isNotNull)
      .filter($"PRODUCCION" >= 0 && $"PRECIO_CHACRA" >= 0)
      .withColumn("EFICIENCIA_SIEMBRA", 
        when($"SIEMBRA" > 0, $"PRODUCCION" / $"SIEMBRA").otherwise(0))
      .withColumn("EFICIENCIA_COSECHA", 
        when($"COSECHA" > 0, $"PRODUCCION" / $"COSECHA").otherwise(0))
      .withColumn("RENTABILIDAD", 
        when($"PRODUCCION" > 0, $"PRODUCCION" * $"PRECIO_CHACRA").otherwise(0))
      .withColumn("CATEGORIA_PRODUCCION", 
        when($"PRODUCCION" > 100, "Alta")
        .when($"PRODUCCION" > 10, "Media")
        .otherwise("Baja"))
      .cache()
    
    println(s"Registros después de limpieza: ${df.count()}")
    
    // ===================================================================
    // 3. CONSULTA 1: ANÁLISIS DE PRODUCCIÓN POR DEPARTAMENTO Y AÑO
    // Estado: Draft
    // ===================================================================
    
    println("\n=== CONSULTA 1: ANÁLISIS DE PRODUCCIÓN POR DEPARTAMENTO Y AÑO ===")
    
    val tiempoConsulta1 = System.currentTimeMillis()
    
    // MapReduce 1: Filtrar y agrupar por departamento y año
    val produccionPorDepartamento = df
      .filter($"PRODUCCION" > 0)
      .groupBy($"DEPARTAMENTO", $"ANO")
      .agg(
        sum($"PRODUCCION").alias("PRODUCCION_TOTAL"),
        avg($"PRECIO_CHACRA").alias("PRECIO_PROMEDIO"),
        count($"CULTIVO").alias("NUM_REGISTROS"),
        countDistinct($"CULTIVO").alias("NUM_CULTIVOS_DISTINTOS")
      )
    
    // MapReduce 2: Calcular ranking por producción
    val rankingProduccion = produccionPorDepartamento
      .withColumn("RANKING_PRODUCCION", 
        row_number().over(Window.orderBy($"PRODUCCION_TOTAL".desc)))
    
    // MapReduce 3: Calcular estadísticas adicionales
    val estadisticasFinales = rankingProduccion
      .groupBy($"DEPARTAMENTO")
      .agg(
        avg($"PRODUCCION_TOTAL").alias("PRODUCCION_PROMEDIO_ANUAL"),
        max($"PRODUCCION_TOTAL").alias("PRODUCCION_MAXIMA"),
        min($"PRODUCCION_TOTAL").alias("PRODUCCION_MINIMA"),
        avg($"PRECIO_PROMEDIO").alias("PRECIO_HISTORICO_PROMEDIO"),
        sum($"NUM_CULTIVOS_DISTINTOS").alias("DIVERSIDAD_CULTIVOS")
      )
      .orderBy($"PRODUCCION_PROMEDIO_ANUAL".desc)
    
    println("Top 10 departamentos por producción promedio anual:")
    estadisticasFinales.show(10)
    
    // Guardar resultados en HDFS
    estadisticasFinales.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/consulta1_produccion_departamentos")
    
    val tiempoConsulta1Final = System.currentTimeMillis()
    println(s"Tiempo Consulta 1: ${(tiempoConsulta1Final - tiempoConsulta1) / 1000.0} segundos")
    
    // ===================================================================
    // 4. CONSULTA 2: ANÁLISIS DE EFICIENCIA DE SIEMBRA POR CULTIVO
    // Estado: Draft
    // ===================================================================
    
    println("\n=== CONSULTA 2: ANÁLISIS DE EFICIENCIA DE SIEMBRA POR CULTIVO ===")
    
    val tiempoConsulta2 = System.currentTimeMillis()
    
    // MapReduce 1: Filtrar registros válidos y calcular eficiencia
    val eficienciaPorCultivo = df
      .filter($"SIEMBRA" > 0 && $"PRODUCCION" > 0)
      .select($"CULTIVO", $"DEPARTAMENTO", $"SIEMBRA", $"PRODUCCION", $"EFICIENCIA_SIEMBRA")
    
    // MapReduce 2: Agrupar por cultivo y calcular estadísticas
    val estadisticasEficiencia = eficienciaPorCultivo
      .groupBy($"CULTIVO")
      .agg(
        avg($"EFICIENCIA_SIEMBRA").alias("EFICIENCIA_PROMEDIO"),
        max($"EFICIENCIA_SIEMBRA").alias("EFICIENCIA_MAXIMA"),
        min($"EFICIENCIA_SIEMBRA").alias("EFICIENCIA_MINIMA"),
        stddev($"EFICIENCIA_SIEMBRA").alias("DESVIACION_ESTANDAR"),
        sum($"PRODUCCION").alias("PRODUCCION_TOTAL_CULTIVO"),
        count("*").alias("NUM_REGISTROS")
      )
    
    // MapReduce 3: Clasificar cultivos por eficiencia y calcular percentiles
    val cultivosClasificados = estadisticasEficiencia
      .withColumn("CATEGORIA_EFICIENCIA", 
        when($"EFICIENCIA_PROMEDIO" > 50, "Muy Eficiente")
        .when($"EFICIENCIA_PROMEDIO" > 20, "Eficiente")
        .when($"EFICIENCIA_PROMEDIO" > 5, "Poco Eficiente")
        .otherwise("Ineficiente"))
      .withColumn("PERCENTIL_EFICIENCIA", 
        percent_rank().over(Window.orderBy($"EFICIENCIA_PROMEDIO")) * 100)
      .orderBy($"EFICIENCIA_PROMEDIO".desc)
    
    println("Top 15 cultivos por eficiencia de siembra:")
    cultivosClasificados.show(15)
    
    // Guardar resultados en HDFS
    cultivosClasificados.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/consulta2_eficiencia_cultivos")
    
    val tiempoConsulta2Final = System.currentTimeMillis()
    println(s"Tiempo Consulta 2: ${(tiempoConsulta2Final - tiempoConsulta2) / 1000.0} segundos")
    
    // ===================================================================
    // 5. PREPARACIÓN DE DATOS PARA MACHINE LEARNING
    // ===================================================================
    
    println("\n=== PREPARACIÓN DE DATOS PARA MACHINE LEARNING ===")
    
    // Seleccionar y preparar datos para ML
    val dfML = df
      .select($"SIEMBRA", $"COSECHA", $"PRODUCCION", $"VERDE_ACTUAL", $"PRECIO_CHACRA")
      .filter($"SIEMBRA" > 0 && $"COSECHA" > 0 && $"PRODUCCION" > 0 && $"VERDE_ACTUAL" > 0)
      .na.drop()
    
    println(s"Registros para ML: ${dfML.count()}")
    
    // Crear features vector
    val assembler = new VectorAssembler()
      .setInputCols(Array("SIEMBRA", "COSECHA", "VERDE_ACTUAL", "PRECIO_CHACRA"))
      .setOutputCol("features")
    
    val dfFeatures = assembler.transform(dfML)
    
    // Normalizar features
    val scaler = new StandardScaler()
      .setInputCol("features")
      .setOutputCol("scaledFeatures")
      .setWithStd(true)
      .setWithMean(true)
    
    val scalerModel = scaler.fit(dfFeatures)
    val dfScaled = scalerModel.transform(dfFeatures)
    
    // ===================================================================
    // 6. MODELO 1: MULTILAYER PERCEPTRON CLASSIFIER
    // ===================================================================
    
    println("\n=== MODELO 1: MULTILAYER PERCEPTRON CLASSIFIER ===")
    
    val tiempoML1 = System.currentTimeMillis()
    
    // Crear variable objetivo binaria basada en la mediana de producción
    val medianaProduccion = dfML.select($"PRODUCCION").stat.approxQuantile("PRODUCCION", Array(0.5), 0.01)(0)
    println(s"Mediana de producción: $medianaProduccion")
    
    val dfClassification = dfScaled
      .withColumn("label", when($"PRODUCCION" > medianaProduccion, 1.0).otherwise(0.0))
      .select($"scaledFeatures".alias("features"), $"label")
    
    // Dividir en entrenamiento y prueba
    val Array(trainClassification, testClassification) = dfClassification.randomSplit(Array(0.8, 0.2), seed = 123)
    
    // Configurar el clasificador
    val mlpc = new MultilayerPerceptronClassifier()
      .setLayers(Array(4, 8, 6, 2))  // 4 input, 8 hidden, 6 hidden, 2 output
      .setBlockSize(128)
      .setSeed(123)
      .setMaxIter(100)
      .setTol(1e-4)
      .setFeaturesCol("features")
      .setLabelCol("label")
    
    // Entrenar el modelo
    val mlpcModel = mlpc.fit(trainClassification)
    
    // Hacer predicciones
    val predictionsMLP = mlpcModel.transform(testClassification)
    
    // Evaluar el modelo
    val evaluatorMLP = new MulticlassClassificationEvaluator()
      .setLabelCol("label")
      .setPredictionCol("prediction")
    
    val accuracyMLP = evaluatorMLP.setMetricName("accuracy").evaluate(predictionsMLP)
    val f1ScoreMLP = evaluatorMLP.setMetricName("f1").evaluate(predictionsMLP)
    val recallMLP = evaluatorMLP.setMetricName("weightedRecall").evaluate(predictionsMLP)
    
    println(s"MultilayerPerceptronClassifier - Resultados:")
    println(f"Accuracy: $accuracyMLP%.4f")
    println(f"F1-Score: $f1ScoreMLP%.4f")
    println(f"Recall: $recallMLP%.4f")
    
    // Guardar predicciones
    predictionsMLP.select($"features", $"label", $"prediction")
      .coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/predicciones_mlp")
    
    val tiempoML1Final = System.currentTimeMillis()
    println(s"Tiempo entrenamiento MLP: ${(tiempoML1Final - tiempoML1) / 1000.0} segundos")
    
    // ===================================================================
    // 7. MODELO 2: DECISION TREE REGRESSOR
    // ===================================================================
    
    println("\n=== MODELO 2: DECISION TREE REGRESSOR ===")
    
    val tiempoML2 = System.currentTimeMillis()
    
    // Preparar datos para regresión
    val dfRegression = dfScaled
      .withColumn("label", $"PRODUCCION")
      .select($"scaledFeatures".alias("features"), $"label")
    
    // Dividir en entrenamiento y prueba
    val Array(trainRegression, testRegression) = dfRegression.randomSplit(Array(0.8, 0.2), seed = 123)
    
    // Configurar el regresor
    val dt = new DecisionTreeRegressor()
      .setLabelCol("label")
      .setFeaturesCol("features")
      .setMaxDepth(10)
      .setMinInstancesPerNode(5)
      .setMaxBins(32)
      .setSeed(123)
    
    // Entrenar el modelo
    val dtModel = dt.fit(trainRegression)
    
    // Hacer predicciones
    val predictionsDT = dtModel.transform(testRegression)
    
    // Evaluar el modelo
    val evaluatorDT = new RegressionEvaluator()
      .setLabelCol("label")
      .setPredictionCol("prediction")
    
    val rmseDT = evaluatorDT.setMetricName("rmse").evaluate(predictionsDT)
    val maeDT = evaluatorDT.setMetricName("mae").evaluate(predictionsDT)
    val r2DT = evaluatorDT.setMetricName("r2").evaluate(predictionsDT)
    
    println(s"DecisionTreeRegressor - Resultados:")
    println(f"RMSE: $rmseDT%.4f")
    println(f"MAE: $maeDT%.4f")
    println(f"R²: $r2DT%.4f")
    
    // Mostrar importancia de características
    println("\nImportancia de características:")
    val featureNames = Array("SIEMBRA", "COSECHA", "VERDE_ACTUAL", "PRECIO_CHACRA")
    dtModel.featureImportances.toArray.zipWithIndex.foreach { case (importance, index) =>
      println(f"${featureNames(index)}: $importance%.4f")
    }
    
    // Guardar predicciones
    predictionsDT.select($"features", $"label", $"prediction")
      .coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/predicciones_dt")
    
    val tiempoML2Final = System.currentTimeMillis()
    println(s"Tiempo entrenamiento Decision Tree: ${(tiempoML2Final - tiempoML2) / 1000.0} segundos")
    
    // ===================================================================
    // 8. ANÁLISIS ESTADÍSTICO ADICIONAL
    // ===================================================================
    
    println("\n=== ANÁLISIS ESTADÍSTICO ADICIONAL ===")
    
    // Estadísticas descriptivas por departamento
    val estadisticasPorDepartamento = df
      .groupBy($"DEPARTAMENTO")
      .agg(
        count("*").alias("NUM_REGISTROS"),
        sum($"PRODUCCION").alias("PRODUCCION_TOTAL"),
        avg($"PRODUCCION").alias("PRODUCCION_PROMEDIO"),
        max($"PRODUCCION").alias("PRODUCCION_MAXIMA"),
        stddev($"PRODUCCION").alias("DESVIACION_PRODUCCION"),
        avg($"PRECIO_CHACRA").alias("PRECIO_PROMEDIO"),
        avg($"EFICIENCIA_SIEMBRA").alias("EFICIENCIA_PROMEDIO"),
        sum($"RENTABILIDAD").alias("RENTABILIDAD_TOTAL")
      )
      .orderBy($"PRODUCCION_TOTAL".desc)
    
    println("Estadísticas por departamento (Top 10):")
    estadisticasPorDepartamento.show(10)
    
    // Análisis temporal
    val tendenciaTemporal = df
      .groupBy($"ANO")
      .agg(
        sum($"PRODUCCION").alias("PRODUCCION_ANUAL"),
        avg($"PRECIO_CHACRA").alias("PRECIO_PROMEDIO_ANUAL"),
        countDistinct($"CULTIVO").alias("DIVERSIDAD_CULTIVOS"),
        avg($"EFICIENCIA_SIEMBRA").alias("EFICIENCIA_PROMEDIO_ANUAL")
      )
      .orderBy($"ANO")
    
    println("Tendencia temporal:")
    tendenciaTemporal.show()
    
    // Top cultivos por producción
    val topCultivos = df
      .groupBy($"CULTIVO")
      .agg(
        sum($"PRODUCCION").alias("PRODUCCION_TOTAL"),
        avg($"PRECIO_CHACRA").alias("PRECIO_PROMEDIO"),
        countDistinct($"DEPARTAMENTO").alias("PRESENCIA_DEPARTAMENTOS")
      )
      .orderBy($"PRODUCCION_TOTAL".desc)
    
    println("Top 15 cultivos por producción total:")
    topCultivos.show(15)
    
    // Guardar análisis estadístico
    estadisticasPorDepartamento.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/estadisticas_departamentos")
    
    tendenciaTemporal.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/tendencia_temporal")
    
    topCultivos.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/top_cultivos")
    
    // ===================================================================
    // 9. MÉTRICAS DE RENDIMIENTO Y RESUMEN
    // ===================================================================
    
    val tiempoTotal = System.currentTimeMillis()
    
    println("\n=== RESUMEN DE RENDIMIENTO ===")
    println(s"Tiempo total de ejecución: ${(tiempoTotal - tiempoInicio) / 1000.0} segundos")
    println(s"Registros procesados: ${df.count()}")
    println(s"Departamentos analizados: ${df.select($"DEPARTAMENTO").distinct().count()}")
    println(s"Cultivos únicos: ${df.select($"CULTIVO").distinct().count()}")
    
    // Mostrar información del cluster
    println(s"\nConfiguración del cluster:")
    println(s"Aplicación: ${spark.sparkContext.appName}")
    println(s"Master: ${spark.sparkContext.master}")
    println(s"Ejecutores activos: ${spark.sparkContext.statusTracker.getExecutorInfos.length}")
    
    // Guardar métricas de rendimiento
    val metricas = Seq(
      ("tiempo_total_segundos", (tiempoTotal - tiempoInicio) / 1000.0),
      ("tiempo_consulta1_segundos", (tiempoConsulta1Final - tiempoConsulta1) / 1000.0),
      ("tiempo_consulta2_segundos", (tiempoConsulta2Final - tiempoConsulta2) / 1000.0),
      ("tiempo_mlp_segundos", (tiempoML1Final - tiempoML1) / 1000.0),
      ("tiempo_dt_segundos", (tiempoML2Final - tiempoML2) / 1000.0),
      ("registros_procesados", df.count().toDouble),
      ("accuracy_mlp", accuracyMLP),
      ("f1_score_mlp", f1ScoreMLP),
      ("rmse_dt", rmseDT),
      ("r2_dt", r2DT)
    ).toDF("metrica", "valor")
    
    metricas.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/metricas_rendimiento")
    
    // ===================================================================
    // 10. CONSULTAS ADICIONALES PARA POWER BI
    // ===================================================================
    
    println("\n=== GENERANDO DATOS PARA POWER BI ===")
    
    // Datos para mapa de calor (Departamento vs Año)
    val datosMapaCalor = df
      .groupBy($"DEPARTAMENTO", $"ANO")
      .agg(sum($"PRODUCCION").alias("PRODUCCION_TOTAL"))
      .orderBy($"DEPARTAMENTO", $"ANO")
    
    datosMapaCalor.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/powerbi_mapa_calor")
    
    // Datos para análisis de correlación
    val datosCorrelacion = df
      .select($"SIEMBRA", $"COSECHA", $"PRODUCCION", $"VERDE_ACTUAL", $"PRECIO_CHACRA", $"EFICIENCIA_SIEMBRA")
      .filter($"SIEMBRA" > 0 && $"COSECHA" > 0 && $"PRODUCCION" > 0)
    
    datosCorrelacion.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/powerbi_correlacion")
    
    // Datos para serie temporal
    val serieTemporal = df
      .withColumn("FECHA", concat($"ANO", lpad($"MES".substr(5, 2), 2, "0")))
      .groupBy($"FECHA")
      .agg(
        sum($"PRODUCCION").alias("PRODUCCION_MENSUAL"),
        avg($"PRECIO_CHACRA").alias("PRECIO_PROMEDIO_MENSUAL"),
        count("*").alias("REGISTROS_MENSUAL")
      )
      .orderBy($"FECHA")
    
    serieTemporal.coalesce(1)
      .write
      .mode("overwrite")
      .option("header", "true")
      .csv("hdfs://master:9000/user/nodo/output/powerbi_serie_temporal")
    
    println("\n=== ANÁLISIS COMPLETADO EXITOSAMENTE ===")
    println("Archivos generados en HDFS:")
    println("- /user/nodo/output/consulta1_produccion_departamentos")
    println("- /user/nodo/output/consulta2_eficiencia_cultivos")
    println("- /user/nodo/output/predicciones_mlp")
    println("- /user/nodo/output/predicciones_dt")
    println("- /user/nodo/output/estadisticas_departamentos")
    println("- /user/nodo/output/tendencia_temporal")
    println("- /user/nodo/output/top_cultivos")
    println("- /user/nodo/output/metricas_rendimiento")
    println("- /user/nodo/output/powerbi_*")
    
    // Detener SparkSession
    spark.stop()
  }
  
  // ===================================================================
  // FUNCIONES AUXILIARES
  // ===================================================================
  
  /**
   * Función para mostrar estadísticas de un DataFrame
   */
  def mostrarEstadisticas(df: org.apache.spark.sql.DataFrame, nombre: String): Unit = {
    println(s"\n=== Estadísticas de $nombre ===")
    println(s"Número de registros: ${df.count()}")
    println(s"Número de columnas: ${df.columns.length}")
    df.describe().show()
  }
  
  /**
   * Función para medir tiempo de ejecución
   */
  def medirTiempo[T](operacion: => T): (T, Long) = {
    val inicio = System.currentTimeMillis()
    val resultado = operacion
    val tiempo = System.currentTimeMillis() - inicio
    (resultado, tiempo)
  }
}

// ===================================================================
// OBJECT PARA EJECUTAR EN MODO STANDALONE
// ===================================================================

object EjecutarAnalisis {
  def main(args: Array[String]): Unit = {
    AnalisisAgricolaPeruSpark.main(args)
  }
}