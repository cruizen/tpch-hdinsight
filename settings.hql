set hive.execution.engine=tez;
set hive.tez.container.size=4096;
set hive.tez.java.opts=-Xmx3800m;
-- set hive.auto.convert.join.noconditionaltask.size=1252698795;
set hive.vectorized.execution.enabled=true;
set hive.execution.mode=llap;
set hive.llap.execution.mode=all;
set hive.llap.io.enabled=true;
set hive.llap.io.memory.mode=cache;

-- Dynamic partitioning in Hive. We tested with the default value as well as the following turned on.
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
