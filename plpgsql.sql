-- создать таблицу

-- docker run -d -p 5432:5432 postgres
drop table if exists test;
create table if not exists test(
    id serial primary key,
    title text not null,
    class_id int default 0,
    reference_id int default 0,
    created_at timestamp not null
);

-- Создадим операцию
insert into test(title, created_at) values('Test operations 1', now());
insert into test(title, created_at) values('Test operations 2', now());
insert into test(title, created_at) values('Test operations 3', now());

-- Выполним сторно...
insert into test(title, class_id, reference_id, created_at)
    values('Storno test operations 1', 8, 1, now());
-- Выполним сторно повторно...
insert into test(title, class_id, reference_id, created_at)
    values('Storno test operations 2', 8, 1, now());

-- Повторная опреация прошла успешна, что является ошибкой.


-- alter table t add exclude (class_id with = , reference_id with =) where (class_id = 8);

insert into test(title, class_id, reference_id, created_at)
    values('Other test operations 1', 4, 1, now());
insert into test(title, class_id, reference_id, created_at)
    values('Other test operations 2', 4, 1, now());


-- Перегруженные функции по количеству параметров
-- Лимитом ограничивать нельзя, так как имеем более одной операции.

DROP FUNCTION IF EXISTS strono_first_or_create(p_id int);

-- Fetch "storn" operation by reference_id.
CREATE OR REPLACE FUNCTION strono_first_or_create(p_id int)
RETURNS SETOF test AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM test t WHERE t.class_id = 8 AND t.reference_id = p_id;
END;
$$ LANGUAGE plpgsql;

-- select * from strono_first_or_create(1);

DROP FUNCTION IF EXISTS strono_first_or_create(p_id int, p_title text, created_at timestamp);

-- Create "storn" operation by given parametrs.
-- Проверить, что полученный p_id существует для id
-- Проверить, что полученный p_id для id не содержит class_id = 8
-- Проверить, что создаваемая операция не существует.

CREATE OR REPLACE FUNCTION strono_first_or_create(
    p_id integer, p_title text, p_created_at timestamp DEFAULT now()
) RETURNS void AS $$
DECLARE
    o_id integer;
    o_class_id integer;
BEGIN
    -- Verify that the identifier transmitted correctly.
    SELECT t.class_id INTO o_class_id FROM test t WHERE t.id = p_id FOR SHARE;

    IF o_class_id IS NULL OR o_class_id = 8 THEN
        -- 😢
        RAISE EXCEPTION 'Operation (#%) can not be found or is not allowed!', p_id;
    END IF;

    -- Determine whether the operation has been performed earlier.
    SELECT t.id INTO o_id
        FROM test t
            WHERE t.class_id = 8 AND t.reference_id = p_id FOR SHARE;

    IF o_id IS NOT NULL THEN
        -- 😢
        RAISE EXCEPTION 'Processed operation (#%) already exists!', p_id;
    END IF;

    INSERT INTO test(class_id, title, reference_id, created_at) VALUES(
        8, p_title, p_id, p_created_at
    ) RETURNING test.id INTO o_id;

    -- RETURN;

    -- RETURN QUERY SELECT * FROM strono_first_or_create(z_id);
END;
$$ LANGUAGE plpgsql;

-- select * from strono_first_or_create(1, 'Lorem ipsum...');
