name := "commitment"

organization := "com.mchange"

version := "0.0.1-SNAPSHOT"

scalaVersion := "2.12.9"

resolvers += ("releases" at "https://oss.sonatype.org/service/local/staging/deploy/maven2")

resolvers += ("snapshots" at "https://oss.sonatype.org/content/repositories/snapshots")

resolvers += ("Typesafe repository" at "http://repo.typesafe.com/typesafe/releases/")

ethcfgScalaStubsPackage := "com.mchange.sc.v1.commitment.contract"
