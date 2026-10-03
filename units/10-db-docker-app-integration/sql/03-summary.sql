SELECT
    status,
    COUNT(*) AS count
FROM
    items
GROUP BY
    status
ORDER BY
    status;
