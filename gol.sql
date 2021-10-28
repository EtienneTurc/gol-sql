WITH RECURSIVE vec(i) AS (
    VALUES
        (1)
    UNION
    SELECT
        i + 1
    FROM
        vec
    WHERE
        i < 50
),
grid_tmp AS (
    SELECT
        x.i as xi,
        CASE
            WHEN RANDOM() > 0.7 THEN 1
            ELSE 0
        END as cell
    FROM
        vec as x,
        vec as y
),
row AS (
    SELECT
        array_agg(cell) as r
    FROM
        grid_tmp
    GROUP BY
        xi
    ORDER BY
        xi
),
start_grid AS (
    SELECT
        array_agg(r) as g
    FROM
        row
),
grid(iteration, g) AS (
    SELECT
        0 as iteration,
        g as g
    FROM
        start_grid
    UNION
    SELECT
        MAX(iteration) + 1 as iteration,
        array_agg(r) as g
    FROM
        (
            SELECT
                MAX(iteration) as iteration,
                array_agg(cell) as r
            FROM
                (
                    SELECT
                        iteration,
                        xi,
                        CASE
                            WHEN previous_cell = 0
                            AND n_alive_neighbours = 3 THEN 1
                            WHEN previous_cell = 1
                            AND (
                                n_alive_neighbours = 2
                                OR n_alive_neighbours = 3
                            ) THEN 1
                            ELSE 0
                        END as cell
                    FROM
                        (
                            SELECT
                                iteration,
                                x.i as xi,
                                g [x.i::int] [y.i::int] as previous_cell,
                                (coalesce(g [x.i::int - 1] [y.i::int - 1], 0)) :: int + (coalesce(g [x.i::int - 1] [y.i::int], 0)) :: int + (coalesce(g [x.i::int - 1] [y.i::int + 1], 0)) :: int + (coalesce(g [x.i::int] [y.i::int-1], 0)) :: int + (coalesce(g [x.i::int] [y.i::int + 1], 0)) :: int + (coalesce(g [x.i::int + 1] [y.i::int - 1], 0)) :: int + (coalesce(g [x.i::int + 1] [y.i::int], 0)) :: int + (coalesce(g [x.i::int + 1] [y.i::int + 1], 0)) :: int as n_alive_neighbours
                            FROM
                                grid,
                                vec as x,
                                vec as y
                        ) as grid2_tmp
                ) as grid2_tmp2
            GROUP BY
                xi
            ORDER BY
                xi
        ) as row2
    WHERE
        iteration < 500
)
SELECT
    *
FROM
    grid
WHERE
    iteration is not null