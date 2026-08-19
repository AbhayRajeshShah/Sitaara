INSERT INTO masterclasses (id, title, description, created_at)
VALUES
    (
        '11111111-1111-1111-1111-111111111111',
        'Early Child Development',
        'Foundational ideas for understanding how young children grow, learn, and connect with caregivers.',
        now()
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'Parenting Wellness',
        'Practical guidance for staying present, communicating as a team, and taking care of yourself while raising a child.',
        now()
    );

INSERT INTO videos (id, title, duration_seconds, masterclass_id, video_url, created_at)
VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
        'How children learn through play',
        596,
        '11111111-1111-1111-1111-111111111111',
        'https://cdn.truefilesize.com/mp4/sample-10mb.mp4',
        now()
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
        'Language and early communication',
        653,
        '11111111-1111-1111-1111-111111111111',
        'https://cdn.truefilesize.com/mp4/sample-5mb.mp4',
        now()
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
        'Building secure attachment',
        888,
        '11111111-1111-1111-1111-111111111111',
        'https://cdn.truefilesize.com/mp4/sample-30mb.mp4',
        now()
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4',
        'Everyday routines that support growth',
        734,
        '11111111-1111-1111-1111-111111111111',
        'https://cdn.truefilesize.com/mp4/sample-50mb.mp4',
        now()
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5',
        'What to notice at each stage',
        60,
        '11111111-1111-1111-1111-111111111111',
        'https://cdn.truefilesize.com/mp4/sample-1mb.mp4',
        now()
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1',
        'Parenting as a team',
        15,
        '22222222-2222-2222-2222-222222222222',
        'https://cdn.truefilesize.com/mp4/sample-silent.mp4',
        now()
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2',
        'Managing stress without checking out',
        15,
        '22222222-2222-2222-2222-222222222222',
        'https://cdn.truefilesize.com/mp4/sample-h264.mp4',
        now()
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb3',
        'Repairing after conflict',
        15,
        '22222222-2222-2222-2222-222222222222',
        'https://cdn.truefilesize.com/mp4/sample-1mb.mp4',
        now()
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb4',
        'Sleep, energy, and asking for help',
        15,
        '22222222-2222-2222-2222-222222222222',
        'https://cdn.truefilesize.com/mp4/sample-5mb.mp4',
        now()
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb5',
        'Staying connected during busy weeks',
        141,
        '22222222-2222-2222-2222-222222222222',
        'https://cdn.truefilesize.com/mp4/sample-30mb.mp4',
        now()
    );