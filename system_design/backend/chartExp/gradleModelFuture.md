在以 Gradle 管理的 Spring Boot 多模組單體（Multi-module Monolith）專案中，**重複配置**（如 `group`、`version`、Java 版本、Maven 倉庫、測試任務等）是常見的痛點。

透過分析您專案中的檔案（如 `build.gradle`、`lychee-erp-basis/build.gradle`、`gradle.properties`），我們可以看到目前這些配置在各個子模組中被重複編寫了：

```6:8:lychee-erp-basis/build.gradle
group = 'com.lychee'
version = '0.0.1-SNAPSHOT'
```

```9:17:lychee-erp-basis/build.gradle
java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(javaVersion.toInteger())
	}
}
repositories {
	mavenCentral()
}
```

為了提高專案的可維護性、遵循 **DRY (Don't Repeat Yourself)** 原則，並為未來的 CI/CD 自動化部署打下良好基礎，建議採用以下**集中化管理**的最佳實踐：

---

### 推薦方案：`gradle.properties` 變數化 + 根目錄 `build.gradle` 統一注入

這是多模組單體專案中最經典、最實用的管理方式。它將「**配置資料**」（如版本號）與「**編譯邏輯**」（如編譯腳本）進行完美分離。

#### 步驟 1：在根目錄的 `gradle.properties` 中定義變數
在專案根目錄的 `gradle.properties` 檔案末尾，加入專案全域的 `group` 和 `version` 變數：

```properties
# 專案組織與版本資訊
projectGroup=com.lychee
projectVersion=0.0.1-SNAPSHOT
```

#### 步驟 2：修改根目錄的 `build.gradle` 進行統一配置
修改根目錄的 `build.gradle`，利用 `allprojects` 和 `subprojects` 區塊，將上述變數與其他重複的配置（如 Java 版本、Maven 倉庫、測試配置等）統一注入到所有子模組中：

```groovy
// 根目錄 build.gradle 推薦配置
allprojects {
    // 1. 統一管理所有專案（含根專案與子模組）的組織與版本
    group = projectGroup
    version = projectVersion
}

subprojects {
    apply plugin: 'eclipse'

    // 2. 統一配置 Java 編譯參數
    tasks.withType(JavaCompile).configureEach {
        options.compilerArgs.add("-parameters")
    }

    // 3. 針對所有 Java/Kotlin 子模組統一配置
    plugins.withType(JavaPlugin) {
        java {
            toolchain {
                languageVersion = JavaLanguageVersion.of(javaVersion.toInteger())
            }
        }

        // 4. 統一配置 Maven 中央倉庫，子模組無需再重複編寫
        repositories {
            mavenCentral()
        }

        // 5. 統一單元測試配置
        tasks.named('test') {
            useJUnitPlatform()
        }
    }
}
```

*註：這裡使用了 `plugins.withType(JavaPlugin)`，這是一種 Gradle 延遲配置的安全寫法。它能確保只有在子模組應用了 `java` 或 `java-library` 插件時，才會注入 Java 相關配置，避免非 Java 模組出錯。*

#### 步驟 3：大幅精簡各子模組的 `build.gradle`
完成上述兩步後，您可以將所有子模組（例如 `lychee-erp-basis`、`lychee-erp-adm`、`lychee-erp-common` 等）中的重複程式碼直接刪除。

以 `lychee-erp-basis/build.gradle` 為例，精簡後的程式碼將變得極度乾淨，只專注於該模組自身的依賴關係：

```groovy
plugins {
    id 'java-library'
    id 'io.spring.dependency-management'
}

// 這裡不再需要寫 group = 'com.lychee'
// 這裡不再需要寫 version = '0.0.1-SNAPSHOT'
// 這裡不再需要寫 java { toolchain { ... } }
// 這裡不再需要寫 repositories { mavenCentral() }

dependencyManagement {
    imports {
        mavenBom "org.springframework.boot:spring-boot-dependencies:${springBootVersion}"
    }
}

dependencies {
    implementation project(':lychee-erp-common')

    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    annotationProcessor "org.projectlombok:lombok-mapstruct-binding:${lombokMapstructBindingVersion}"
    annotationProcessor "org.mapstruct:mapstruct-processor:${mapstructVersion}"
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}

// 這裡不再需要寫 tasks.named('test') { useJUnitPlatform() }
```

---

### 這樣做帶來的巨大優勢

1. **單一事實來源（Single Source of Truth）：**
   未來升級版本號（例如從 `0.0.1-SNAPSHOT` 升級為 `1.0.0-RELEASE`）時，**只需要修改根目錄的 `gradle.properties` 一個地方**，所有子模組會自動同步更新。
2. **極佳的 CI/CD 兼容性：**
   在自動化構建流程中，CI/CD 工具（如 Jenkins, GitHub Actions）不需要修改任何 `build.gradle` 程式碼。可以直接透過命令列參數動態覆蓋版本號進行打包：
   ```bash
   ./gradlew build -PprojectVersion=1.0.0-RELEASE
   ```
3. **消除大量樣板程式碼（Boilerplate Code）：**
   子模組的 `build.gradle` 檔案行數將減少 30% ~ 50%，程式碼結構會更清晰，開發人員能一眼看出該模組「依賴了哪些東西」，而不會被通用的設定干擾。

---

### 進階考量：現代 Gradle 的「約定插件」(Convention Plugins) 方案

雖然上述的 `subprojects` 方案對當前的單體架構已非常完美，但如果您未來的專案規模持續擴大（達到數十個模組），Gradle 官方目前更推薦使用 **Convention Plugins（約定插件）** 方案。

* **為什麼？** Gradle 官方認為 `allprojects` 和 `subprojects` 這種「跨專案配置注入」會導致模組間強耦合，可能會影響 Gradle 的「配置快取（Configuration Cache）」效能，並在極大型專案中拖慢編譯速度。
* **如何實作？**
  1. 在專案中建立一個特殊的 `buildSrc` 目錄或 `build-logic` 複合建置目錄。
  2. 在其中編寫自定義的 Gradle 插件（例如 `com.lychee.java-conventions.gradle`），把 group、version、Java 版本、編譯參數寫在該插件中。
  3. 子模組只需要在 `plugins {}` 區塊中引入這個自定義插件即可：
     ```groovy
     plugins {
         id 'com.lychee.java-conventions'
     }
     ```

**💡 建議：**
由於您的專案目前是結構清晰的單體多模組專案，**採用上述的「`gradle.properties` + 根目錄 `build.gradle` 統一注入」方案是投資報酬率（ROI）最高、改動最簡單且最直覺的選擇**。未來若專案模組數量增加到 30 個以上且遇到效能瓶頸時，再平滑遷移至 Convention Plugins 即可。