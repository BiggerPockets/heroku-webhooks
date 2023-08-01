class Event < ApplicationRecord
  def application
    payload.dig('data', 'app', 'name') || '<unknown>'
  end

  def name
    "app.#{resource}.#{action}"
  end

  def name_in_past_tense
    "#{name}d"
  end

  def resource
    payload['resource'] || '<unknown>'
  end

  def action
    payload['action'] || '<unknown>'
  end

  def user
    payload['actor'] || {}
  end

  def utm_campaign
    payload.dig('context', 'campaign', 'name')
  end

  def utm_medium
    payload.dig('context', 'campaign', 'medium')
  end

  def utm_content
    payload.dig('context', 'campaign', 'content')
  end

  def utm_source
    payload.dig('context', 'campaign', 'source')
  end

  def utm_term
    payload.dig('context', 'campaign', 'term')
  end

  def compressed_utms
    "c::#{utm_campaign}/m::#{utm_medium}/s::#{utm_source}/t::#{utm_term}/c::#{utm_content}"
  end

  def user_id
    payload['userId']
  end

  def anonymous_id
    payload['anonymousId']
  end

  def email_generated_guid?(id)
    id.to_s.match?(/^e:[0-9a-fA-F]+$/)
  end

  def guid?(id)
    id.to_s.match?(/^(r:|)[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/)
  end

  def fake_guid?(id)
    id.split('-').any? && id.split('-').all? { |group| group.size == 4 }
  end

  def user_id_format
    if user_id.blank?
      'blank'
    elsif user_id.match?(/^[0-9]+$/)
      'social_user'
    elsif fake_guid?(user_id)
      'fake_guid'
    elsif guid?(user_id)
      'guid'
    else
      'invalid'
    end
  end

  def anonymous_id_format
    if anonymous_id.blank?
      'blank'
    elsif guid?(anonymous_id) || email_generated_guid?(anonymous_id)
      'guid'
    elsif fake_guid?(anonymous_id)
      'fake_guid'
    else
      'invalid'
    end
  end

  def user_id_fake_guid?
    user_id_format == 'fake_guid' && ALIASED_USER_IDS.exclude?(user_id)
  end

  def anonymous_id_fake_guid?
    anonymous_id_format == 'fake_guid'
  end

  def user_id_invalid?
    user_id_format == 'invalid'
  end

  def anonymous_id_invalid?
    anonymous_id_format == 'invalid'
  end

  def user_or_anonymous_id_invalid?
    user_id_invalid? || anonymous_id_invalid? || user_id_fake_guid? || anonymous_id_fake_guid?
  end

  def user_and_anonymous_id_valid?
    !user_or_anonymous_id_invalid?
  end

  def payload_errors
    payload_errors = []
    payload_errors << { code: 'event.user_id.invalid' } if user_id_invalid?
    payload_errors << { code: 'event.anonymous_id.invalid' } if anonymous_id_invalid?
    payload_errors << { code: 'event.user_id.fake_guid' } if user_id_fake_guid?
    payload_errors << { code: 'event.anonymous_id.fake_guid' } if anonymous_id_fake_guid?
    payload_errors
  end

  def self.truncate_to_recent!
    order(created_at: :desc).offset(100).in_batches.destroy_all
  end

  ALIASED_USER_IDS = %w[
    b169-7755-2d25-8aa5-ebfa-ab5b-98ab-8132
    4da8-354b-da2c-3dfb-62fe-324c-153f-af4d
    c3de-20b7-600d-0a84-5a6b-6d0d-2999-7683
    1534-e3d1-600a-c247-0d30-0f36-afc8-91f6
    5be7-528d-156b-d77f-603c-bda4-00d2-1f12
    2ee1-45cf-e00e-031d-8ace-5ff7-9a45-d0ef
    4461-c2f0-83aa-11cd-4287-c25f-6f29-596a
    f25f-b0de-5595-a185-37b4-98a0-88b4-40c2
    67a7-d6f3-867a-05ce-7269-6547-3758-ead6
    675e-ff57-3dbf-149b-d94e-724f-d433-6a8c
    9d57-9521-7210-5ce1-c429-5721-300f-1be5
    dcbc-2b5f-48c1-ff0b-2bc0-9761-b95c-7dac
    dc88-20b2-a70f-0f32-c92d-8342-d06a-f5f9
    4473-139c-c390-bb71-dc92-e90f-56cf-2f87
    154a-1594-ceeb-c562-0418-339e-c982-1476
    d999-6fa1-ed6b-1143-617f-ff94-2060-ef19
    c12b-b739-06fe-5543-a2c0-c136-736e-b5c5
    6f73-31de-aad5-0adb-3912-c0b4-8424-a9cc
    7713-242e-e1f2-1a8f-69b1-6f40-eede-e185
    2fd4-9c0b-6d49-e838-ccf7-7399-969f-1e9d
    0079-d3e4-2579-f56e-6e4f-a6fb-8c55-5eaa
    f179-1ccf-f6ef-36ba-9a67-d75f-4ac2-ff1f
    b4d4-d755-b8c5-c454-2f5a-c109-c1c7-799c
    7912-18f4-7008-5763-7c17-f61d-0f89-9457
    a61d-e96d-5de4-02c5-7e3a-2cdf-7985-c92d
    c315-f1da-5ba7-84e2-2676-af30-929e-c908
    7efe-e29f-e978-46bb-9a36-0c99-6cbd-7ac8
    bb9c-03cc-60d0-6f79-0b60-7320-c385-51de
    1f11-a620-7218-037d-4408-a781-10ef-9ed6
    00c6-4487-8784-605a-9046-308a-813c-0748
    8d81-9aef-df7d-e5ce-4f43-c180-7fb3-d909
    c935-87ad-9804-6838-38e4-e86b-7c72-b010
    ea21-5a38-e7b0-b17c-4615-2a3f-206c-1bf5
    db18-284e-c5f5-afae-1787-8af8-2219-540f
    152a-3649-5623-ff5d-477d-a299-a3ea-ce9e
    bbd8-6858-a5f9-ca53-5e35-f1f1-3105-d057
    96cc-95f6-2be3-ea36-8dad-6d54-3c91-effe
    e409-8175-6a74-ef12-ac84-6c70-58f8-2810
    543c-af8b-6c36-8d2a-7a0e-a924-73d5-47a2
    a441-8fe4-31ca-d41f-b6b4-7869-1cd0-4fd2
    9740-3a3b-407b-8d82-53e2-d0f6-068e-ff68
    1900-01c5-2a51-065a-360e-6a84-dd0e-e4fc
    80a7-fc94-eba8-c3f9-bc2e-3fac-e501-1ce8
    007d-dd62-be75-f0c3-fa5b-5baf-e2c7-1954
    4a12-5803-d0d4-5c3c-719f-327b-f3a2-8f05
    4b79-3f5e-5c57-6304-9542-6098-244a-d536
    a01b-0e28-4df3-ffd5-36e4-695d-ca38-a497
    ef69-1bac-c0eb-0b2c-e584-7950-d5fb-f7c3
    86ea-ea14-829c-c9ca-bb6c-3212-7eac-0954
    eb50-0477-29b6-269f-9a2f-b441-5d6e-fd8d
    d22d-2a19-47e2-0938-37ba-bbd1-2cc7-06c4
    30f8-f073-caad-5530-bde3-685a-ff24-5fd8
    1f0c-7e7a-6127-8543-b9f5-ad32-d6f3-4d3b
    312d-4acc-c577-8eed-13c5-ca30-c97c-e5be
    f646-df1e-b784-7a82-4ca4-db2f-5bfe-355e
    0a12-f08f-a9a1-3da8-a76a-951d-6718-88f8
    36d4-e6f6-33fb-4d13-eae9-f9f3-99a1-48c1
    1493-5426-88db-64da-cfae-78ed-d791-09cb
    674a-31de-9c9b-9f6c-93fd-f2d3-3103-5f92
    11c2-985f-c225-2bb1-7677-6fdd-3c0f-559e
    bdd5-77ba-6f55-1299-76df-a313-e01f-5252
    9fe3-a76e-206f-5ef5-1dee-d897-79f1-1425
    c19e-050e-67a1-6639-b5cd-da4f-725f-ffd2
    ec96-988b-6a91-124c-c1dd-c80b-ee5b-f608
    3e81-647c-b853-18e4-2cfd-12d7-7225-ed10
    69a8-7b6d-e063-c915-6176-97ca-5e96-414a
    1fdf-398a-cdf9-8116-da95-ece7-669e-7237
    cf92-c245-3e8e-6fc7-564c-6d93-9fab-d031
    162c-88fc-aa8c-5f09-6e26-6136-433c-e375
    567a-4eae-214b-a59f-330b-d839-5587-11de
    e5df-f424-49a1-aca2-28cb-319b-817d-bb85
    f6ac-171b-5241-3423-8c42-ecae-7527-959f
    1d94-fd63-8c12-cc82-aea7-86b9-3c13-8c7a
    ea16-aea6-b2b2-a3e8-83ce-9073-917a-264a
    7de7-70b5-a071-ddc7-dbbc-96e5-1ac9-1bc3
    f3ed-56af-7520-20be-bdd5-d285-7830-9ea3
    a0f0-9337-f4a4-3957-5cfb-07a8-1ae2-a3aa
    503e-0ae6-8621-1cd9-5ecc-770c-ebeb-1338
    bb4a-a9c7-8cc3-7981-82b6-f372-4c8c-9a22
    3897-1d13-4d16-b341-d19d-42d3-08af-faa3
    7759-5b0c-63ab-0015-f9fc-3ce9-0e9d-5b51
    9443-ff36-ddd8-154b-3b75-c9db-729b-5e9d
    ae7d-b5ee-eea3-e4d3-035f-c356-586f-1809
    facd-b31d-b71b-558b-ee75-4bfa-3968-c0b9
    fb19-93b4-7431-ef1e-d4f6-e31f-055c-246d
    1035-7ef9-b45e-0f69-5488-1617-5551-7517
    bb47-d1de-b909-8e23-ac12-4749-a8c6-987f
    47ae-26e2-3a07-5bf5-2eca-0e8d-4e71-e62c
    3fe7-f7bd-c230-fd31-a5be-1cbd-ed01-52bb
    3f3a-33cd-0752-8b75-8809-d202-a3bc-5c26
    9ffe-5b31-2a26-f806-c39e-840e-a021-387e
    7ef8-e7cd-4156-19f8-6301-f65a-0202-43db
    f7af-0b11-c072-c659-e068-50a3-bcbb-9a2f
    fe3c-73cd-ae54-6f90-4d5f-9160-f722-092f
    8509-ddc8-10e8-54a8-b62b-5b67-9987-1173
    7df7-0401-121d-161c-5098-8aa1-f228-3084
    2e9e-dba7-4b9e-6dbf-6f9e-84a1-e310-7a85
    8382-7f06-c6e8-e533-6101-395e-cf9a-25d6
    3258-66a2-28ee-7469-e1a2-6ad1-2380-afbf
    cf1c-d816-c40e-f36b-b341-79a7-6187-b1e0
    edcf-e0cf-2934-ce0d-6d4c-efed-4df8-b7a5
    37c9-c9a0-4563-dd0c-0248-ac3f-4c56-9ee0
    d817-cf34-3ca9-9253-26f9-4581-49e0-6259
    687f-49f8-d067-a2cc-58c5-1616-4948-9247
    7dce-5974-a9ba-14ec-3d66-64e8-3042-d7e7
    b113-fa45-a7c3-6caf-780e-4971-35fa-374c
    ab64-70b2-28e9-34d3-c516-366e-ae61-6b28
    3f30-ffb3-2e41-0d48-4945-e5cd-b07c-f41e
    11ba-f91c-34a6-844d-dfd0-b7e4-0e05-00f6
    b1c7-834b-5457-0927-f39e-574c-7c8d-96fd
    31c5-a3b0-6c46-e1d5-b820-7259-7885-7e7c
    d8af-71db-ef15-ec52-ccb2-a619-1246-f72f
    a3af-d883-ea5d-918a-7224-c405-d980-2ed2
    246f-8001-fe59-a4e3-aa6d-a13f-fb38-ad78
    b85f-6cd6-bd5e-c5c5-e66b-7463-4708-af59
    fdbe-9e68-e12f-d333-9217-efbe-8037-9104
    3893-e27b-1a03-a347-8ea7-fbab-6e83-643e
    82ed-19ca-8426-2e33-9f1d-95cd-d2a2-6eef
    2f1a-32a2-65ff-964f-85e7-c10c-61ba-042e
    fd52-f901-b3e0-a9ce-8974-77fd-e729-cdfe
    c3a1-802d-206f-5b42-31b6-5f44-8c9e-d684
    cd6c-5972-7727-f113-db79-74ea-66ef-bd5b
    070b-ec24-1550-4b14-8951-63b7-c458-0e63
    dd9e-abd0-9d3f-7007-c2f1-3e84-4612-6ce2
    0ea2-c2af-f132-73a6-c8b3-9462-d772-fe4b
    f574-9e9a-0099-e34a-de2e-46e7-6d88-b485
    4d29-bac9-30c3-1879-c102-06b6-f625-a918
    014a-b944-861b-cb6d-7ca4-146d-eed7-0763
    1968-27b8-bef6-dd49-a545-a685-d078-6709
    b2ff-5143-4cd8-7c5a-2860-008a-1a9f-1b4d
    ee40-0ded-ed4c-77e2-d2bc-fb7b-e21a-48be
    5e2a-2343-547d-6041-6164-2370-9575-8e80
    b81c-e3d1-c555-29ab-2a1e-9ea1-05f5-2ded
    72a8-2b18-0d0f-448b-e26c-dae1-a9dc-72d9
    b11c-2881-1920-ed13-7f07-efa6-5c84-cc4c
    48fe-87cd-0f47-58de-53c7-8836-3865-9a02
    3c5d-c194-e9c8-178d-f38d-4009-4605-6c66
    c48a-0fca-eb00-9c53-f69a-0b73-c174-3c5d
    d2ce-8d3f-a96f-edc4-9fe6-c6df-5d4f-71f5
    a54f-cd06-35c0-383f-c764-c9eb-0227-421c
    3dd9-8438-acc9-c8ff-4ffb-89df-83e4-cedb
    206b-47b3-f69f-94b4-7d54-3cb6-8fca-aadf
    879a-1ced-ac43-cee1-23ec-e291-413d-7e22
    da09-ce34-8f90-f71c-7e6b-c8c5-ebf6-8661
    b497-ca22-3346-3b8d-a7d1-58b6-648f-dde2
    105c-a56a-bc65-1040-bf3c-00dd-1477-e19d
    6f5f-871e-e09f-4add-716a-46e5-0ed5-e7f1
    b78f-0637-c5f7-b2c8-cf5f-d42f-13bb-66b4
    5599-c969-56f6-fcd8-c431-3b05-28b4-a8f5
    9622-726a-0ada-e349-8b8d-61b7-1824-61ec
    1388-c2b9-4924-0e4a-9792-8a29-be7a-542b
    7b31-2733-5590-2d10-36c4-f5d9-4569-517a
    d8e4-963e-0a8d-5c77-d3f1-6457-a783-a187
    3205-2bf7-1a05-446d-2f73-b259-5768-044e
    f034-813b-a0fd-9d4d-e9a0-cc2f-8d1a-885b
    613c-1588-7785-d30f-96ba-b0ad-0741-a653
    418a-f411-5d70-0ad5-5ae4-0f2d-3247-0913
    d114-c0c9-34eb-e51b-b06e-5f7a-d4fc-733b
    9cb7-96fb-cf4c-f27d-4f1b-f7fd-3257-4f00
    d081-1171-45f1-9de9-8b4c-47a4-d9d9-b75b
    bfdc-639d-d336-9f9c-cd47-84aa-ecf5-74c2
    68dc-e310-1af1-fa1b-7d74-a906-7adb-5e42
    347c-eef9-ddc9-f2ce-dede-b940-cc93-5fbe
    36af-6ab9-27c1-9314-d82f-fd8e-5245-eb47
    3185-5064-e37d-90da-e788-51c7-fa94-23ad
    1041-f8f2-ff2e-6127-5f7e-ace5-c4e5-9535
    fd8a-1efa-b58e-b587-e219-80ec-fd6f-0269
    ff71-204f-51a9-0980-1453-8f4e-bbf3-7d00
    1c1e-617a-4961-e2b3-0568-24c1-5fcf-ac88
    7494-a8c2-9139-2d25-48e4-8d26-7faf-1918
    b236-07a9-9342-94e7-b3a2-8a3c-ed12-7ec5
    ef7c-29f4-3963-37c7-caf9-0243-97ca-091a
    9788-1b43-361b-1288-38fa-4d4b-1e26-c4fd
    eeaf-f8e9-130e-d135-9890-b33b-19fa-ebf9
    81c7-c3ca-c062-f8b9-c75e-fae6-4a51-5822
    f80a-0cc3-665b-df17-5f68-7b2c-b6db-1478
    40d5-b91b-9e6c-7a6c-8b90-5df4-5ad1-1050
    2bb2-b071-0ec6-878e-14ba-ce66-5a3f-7c25
    7b20-5a09-4c6b-88ad-23d7-1eaf-043b-f884
    62fc-09af-7676-c44c-b0c7-19cd-e585-3ea7
    e526-8dbf-9dc2-0136-bae7-7168-4ac1-208d
    a005-e335-3069-d3b1-b7f9-8b12-b08e-adc2
    9864-e335-0af6-e7d3-f705-f90a-694b-9e8a
    2b25-db39-6fea-62df-70c9-f54a-d55b-1519
    31ca-3b0c-f3ff-6535-88de-e053-2f7b-5918
    d8d6-3272-8d47-8cc0-715d-2605-6622-7da8
    d4ea-2044-1bd3-9c3f-98db-9ee1-e932-a5eb
    1c47-e7df-8430-5e48-b4cf-eea4-97e1-e5e9
    072b-91b1-1408-dd39-8da7-d1db-372d-abf8
    f672-e50a-ecba-7302-085d-5cec-ba10-6f58
    b56c-a5f3-bf05-b43f-be66-b387-45e1-77ca
    3ec1-b8c8-1a31-ade4-cd82-6e01-ed35-cd76
    dd26-0c12-1ebc-240c-fd1e-f6dd-77dc-ce36
    1dad-f65d-086e-0198-f3e6-7488-dad7-8242
    9607-bc6b-b8ba-deaa-bda9-8948-2c93-a802
    4103-fd6f-0b16-a44f-3a8d-20c0-6c74-5944
    f7ff-d937-8bbf-662e-a782-3fd7-be92-0c9f
    c1e2-91ad-b8cc-a2ba-cfd9-5491-68e4-617c
    bb24-e2ad-a9fc-632d-202a-c171-8ce8-56ff
    11a1-24ab-768c-e21c-ce6d-1ca8-b58b-bf3c
    a15d-08a6-7d42-742a-b7e1-3e9f-6f33-abf6
    5758-ece6-00a0-3160-80b0-b9cb-8a6e-db23
    333a-5b4f-bfe2-2b37-e286-0e0c-6975-9865
    41ba-6282-cac8-d701-17fa-5f4b-108c-1d42
    ef9e-8059-47e4-8130-4c97-d786-e126-5f39
    fca6-5759-234f-0d39-ca2c-de56-d4f1-bcb9
    583f-9579-5af3-bd9a-7ece-406e-70d0-5fd5
    7041-0215-ae65-4b54-68b6-4b8a-5d72-3635
    338a-3c61-752a-453b-92d7-0ed8-8feb-50dd
    fabb-1a73-1d44-3d37-67ef-1d68-d16c-80c4
    82b0-bcb0-9ce9-25ff-f34d-c509-579e-c2c9
    8cec-d7d3-bc5d-ad5b-4bce-984f-b49b-e8dd
    283d-8187-61fe-4b9d-af18-20b3-01b5-c6e0
    f2be-77b8-ebb2-1f4f-983a-acb9-85f9-4fd9
    894c-dbb5-7812-37bb-8ba5-54fa-f37b-40b5
    ad71-059e-39af-15fd-8774-159f-309d-a2cd
    bdfe-aca5-c3fc-fb02-17f9-835f-7e35-f2ef
    e72f-cd93-51a0-3d97-0721-98a5-01c2-77a2
    336d-c458-67cb-b94f-d53b-bee6-6b68-7153
    026a-82a1-7b16-cea4-384f-48a2-bc74-927a
    52f8-5381-a7fe-2542-ba0a-7f6a-e451-a7b0
    2aed-5ae1-4b04-dc36-0945-2826-8b0d-9652
    d99f-08c4-6684-b850-bc00-4cd5-94d4-5323
    4776-d9b8-3e02-3fdd-408b-0b93-9564-a06d
    1fdb-c39a-a675-bd89-373f-1ffa-94b2-2def
    afb1-be4f-a42b-09f5-e69e-b545-002d-c0c1
    25ba-f01e-74c8-25a7-caab-7336-84b6-bcc2
    8b07-a84c-2824-dd22-ebe2-8a5c-df22-24b1
    0703-f0a6-5cca-3c17-1886-d118-7d55-e62d
    66bf-c82c-523c-c23d-1a56-651a-2b24-a8c9
    bebf-937a-24ba-74f1-9507-0060-3ce2-cac9
    58bc-e762-678d-d26d-ecad-68da-661b-ed4a
    4b80-a282-dd12-21ab-5c29-18d4-40cd-b187
    a602-77a9-6fd9-9aaf-1530-1895-533e-3c23
    c9cb-9f85-2691-1d4f-263d-7bf9-5b5f-ba21
    4b47-4bd0-edb6-99c3-e98d-7be1-2004-b297
    53e5-2da8-85a3-2088-a08d-0ad3-ea59-1fd3
    6f03-6066-797f-9a94-10c1-4072-756f-2e53
    8ca6-ef02-c2f9-b50d-c75f-f86c-5592-d2f7
    601e-592e-ebfa-991e-faa2-a685-c0f0-47e2
    937d-8d9f-0c85-a0c8-24c5-5ec1-6fb7-a936
    715c-15e7-97b7-9330-c1e6-ffe4-a36a-9cfa
    5d49-3168-f731-170d-e1c1-1eca-838e-5fea
    f744-5911-3e95-3151-5893-cfc6-6b83-8575
    be62-0492-3e72-baec-74d6-bf98-1c37-93e7
    f29b-05cc-bccb-048e-c4f2-5873-c720-8a62
    a779-26c2-d208-172c-c474-ec27-d71a-8ff0
    f67d-b9e0-99b3-21ee-8631-5c53-bab3-f57b
    e71a-9fb5-ffb1-ca3b-b0dc-75be-4fe0-dfb3
    67aa-0fc7-6c9d-a995-9570-9021-b0a9-6556
    7fcc-3731-d5ac-31b4-6fb8-bbc0-1a46-200b
    96bb-c0ed-2f6e-d29c-c8ea-6c9e-a8bc-d43c
    86df-b6c7-5bfa-48f4-c895-fb4e-dd93-23aa
    43f6-fc2f-aae6-ba48-4590-657c-57c2-ce4d
    a6be-0d9b-d4d3-b986-0f12-ea15-ce42-8643
    953c-be56-1385-fb2e-ba24-1726-828e-e9ef
    e15d-943e-25d6-73a4-8d28-fd1b-1694-5d1d
    cbce-a587-ba95-f946-c074-eb74-1792-4946
    8034-d501-7170-35cc-abba-69a4-557a-c8ce
    ae5e-c376-1144-78e0-a19e-5d4d-987c-1da0
    7ec4-c716-60af-f4de-eb60-1629-d99c-1849
    6aed-7941-5f85-2537-b2c8-8098-708d-9c55
    3c55-a14c-e8ac-0e7f-3aa5-c521-db03-fd72
    3ecd-e15e-2d08-64fe-943f-2131-d216-e311
    e1c2-f8d9-de4e-dcda-36f5-bae5-6d7c-6c64
    57da-9444-2054-e408-0e6d-a5fd-fac7-d7b2
    169a-9e0d-7938-cf42-1021-a3d4-75e1-a93a
    b72b-ca5a-c27e-1374-0e33-5db5-f845-057d
    95cf-06c3-0709-adfc-8680-6216-199a-9cef
    7412-fb2a-f795-c8e2-fff3-b9f1-2155-c1f3
    b513-08b3-9cbb-1e0b-97db-cd4c-25cb-91e2
    e3ba-f0ea-afc2-e961-e2ad-68ff-5a67-358a
    ff43-63e3-6019-74fb-382e-2663-c859-5ef9
    8d88-e2ca-741a-35c6-9e1c-e780-e58b-f19f
    8245-eec6-49a4-656c-d87a-44e0-f245-ce75
    d2b6-be26-b93a-149f-8e17-3d3f-c4cd-11d3
    eb03-0479-7370-4777-0346-3dc7-6971-2f92
    a943-5f7a-891e-60db-e676-3957-41e6-9857
    9149-4205-321f-e06f-2f56-747d-180a-cc3c
    9482-777a-1413-f935-86fa-ba6c-d923-1295
    594a-7e1f-4f1e-eea9-91c6-b5b3-e6fc-e801
    8ae9-4235-8a75-8b4b-0d64-168e-861e-e084
    5842-0d25-38ca-748f-8c8d-2f7e-1bab-805d
    5263-72d5-0f5f-360a-061a-1453-33f8-7f62
    7cb8-8a19-40b7-b6b3-622c-5bc6-5c78-d3fd
    788c-1c73-a88a-c5b5-8e4e-6d62-394d-e9ad
    f278-3e64-c3e8-1433-0b38-4d39-2a0c-cc97
    d798-9630-4cab-6014-6c6c-2608-fbec-6e51
    35a1-2fb8-9a95-7353-e897-71a4-44b6-a3f7
    20e8-43d9-e43e-249e-835c-1bdc-eaa1-0067
    6763-d6a6-28a6-715b-2e86-6b62-3000-ff18
    7958-2b0e-8f4f-f047-8f0f-5604-9d6f-fe1f
    4898-381f-78de-3822-5903-3731-b92f-262b
    d6a2-a84f-71e3-0d01-b6cc-5f36-c501-e10c
    69c0-cf7b-0e68-5f6f-7de2-1e6b-5f34-4057
    b7dd-18cd-8556-100c-dde4-2198-c7a2-3ad8
    af33-c13b-77e3-ef82-7ed4-a77a-6b39-c26e
    0d6b-b797-9d50-a335-8a03-3fc6-b09e-5967
  ].freeze
end
