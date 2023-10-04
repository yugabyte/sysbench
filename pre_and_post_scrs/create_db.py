import psycopg2
import argparse

def create_db(arg):
    if len(arg.pwd) == 0:
        conn = psycopg2.connect("host={} dbname=yugabyte user=yugabyte port=5433".format(arg.db))
    else:
        conn = psycopg2.connect("host={} dbname=yugabyte user=yugabyte password={} port=5433".format(arg.db, arg.pwd))
    conn.set_session(autocommit=True)
    cur = conn.cursor()
    for i in range(1, arg.num+1):
        print("Dropping database if exists perdb_{}".format(i))
        cur.execute("DROP DATABASE IF EXISTS perdb_{}".format(i))
        print("Creating database perdb_{}".format(i))
        cur.execute("CREATE DATABASE perdb_{}".format(i))

def main():
    parser = argparse.ArgumentParser(description='Enter the Yugabyte Cluster IP, Username, Number of databases to be created')
    parser.add_argument("-d", type=str, action="store", dest="db", required=True)
    parser.add_argument("-p", type=str, action="store", dest="pwd", required=True)
    parser.add_argument("-n", type=int, action="store", dest="num", required=True)
    args = parser.parse_args()
    create_db(args)

if __name__ == "__main__":
    main()
