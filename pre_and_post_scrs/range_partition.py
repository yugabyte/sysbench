import psycopg2
import argparse

def create_tables(arg):
    conn = None
    try:
        if arg.pwd and len(arg.pwd) == 0:
            conn = psycopg2.connect("host={} dbname=perdb_{} user=yugabyte port=5433".format(arg.db, i))
        else:
            conn = psycopg2.connect(
                "host={} dbname=yugabyte user=yugabyte password={} port=5433".format(arg.db, arg.pwd))
        conn.set_session(autocommit=True)
        cur = conn.cursor()
        for i in range(1, arg.num + 1):
            print("Droping table sbtest{}".format(i))
            cur.execute("DROP TABLE IF EXISTS sbtest{}".format(i))

        for i in range(1, arg.num + 1):
            print("Creating table  sbtest{}".format(i))
            cur.execute("CREATE TABLE sbtest{}(id SERIAL,k INTEGER DEFAULT '0' NOT NULL,c CHAR(120) DEFAULT '' NOT NULL,pad CHAR(60) DEFAULT '' NOT NULL,PRIMARY KEY (id ASC) )".format(i))
            #cur.execute("CREATE INDEX k_{} ON sbtest{}(k)".format(i,i))
    except psycopg2.DatabaseError as error:
        print(error)
    finally:
        conn.close()

def main():
    parser = argparse.ArgumentParser(description='Enter the Yugabyte Cluster IP, Username, Number of databases to be created')
    parser.add_argument("-d", type=str, action="store", dest="db", required=True)
    parser.add_argument("-p", type=str, action="store", dest="pwd", required=False)
    parser.add_argument("-n", type=int, action="store", dest="num", required=True)
    args = parser.parse_args()
    create_tables(args)

    # for i in range(1, args.num + 1):
    #     create_tables(args, i)

if __name__ == "__main__":
    main()