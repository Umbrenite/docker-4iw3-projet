<?php
$dsn = "pgsql:host=database;port=5432;dbname=database";
$username = "postgres";
$password = "admin";
$pdo = new PDO($dsn, $username, $password);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$sql = "SELECT * FROM todo";
$result = $pdo->query($sql);
$rows = $result->fetchAll(PDO::FETCH_ASSOC);
var_dump($rows);