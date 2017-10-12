defmodule Librarian do
@moduledoc """
downloadFullLibrary grabs all xml from Synapse server

loadData is used by the CardData agent
"""

# @file_dir Application.get_env(:spellstone_xml, :file_dir)
# @files Application.get_env(:spellstone_xml, :files)

  def downloadFullLibrary do
    download Application.get_env(:spellstone_xml, :files)
  end

  def download files do

    headers = [
      "User-Agent": "spellstone_xml/0.1a",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.5",
      "Accept-Encoding": "gzip", # watch this.  must manually decode
      "Connection": "keep-alive",
      "Content-Type": "application/x-www-form-urlencoded",
    ]

    timeout = 30000 # 30 seconds

    secure_url_prefix = "https://spellstone.synapse-games.com/assets/"

    request_options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: timeout]

    Enum.map files,
      fn(name) ->
        filename = name <> ".xml"
        url = Path.join(secure_url_prefix, filename)
        output = Path.join(Application.get_env(:spellstone_xml, :file_dir), filename)
        case HTTPoison.get(url, headers, request_options) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            # FIXME, assumes content is gzipped
            data = :zlib.gunzip(body)
            {:ok, file} = File.open output, [:write]

            IO.binwrite file, data
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            IO.warn url <> ": not found :("
          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.inspect reason
          a ->
            IO.inspect a
        end
      end
  end


  defp map_by_id list do
    Enum.reduce list, %{}, fn(ele,acc) ->
      Map.put(acc,ele.id,ele)
    end
  end

  def loadData filename do
    import SweetXml

    skill = [
      ~x"./skill"l,
      id: ~x"@id"s, # |> transform_by(&id_to_atom/1), -- hm, avoid ss specific info!
      skill: ~x"@s"o,
      timer: ~x"@c"Io,
      value: ~x"@x"Io,
      affinity: ~x"@y"Io,
      all: ~x"@all"I
    ]

    upgrade = [
      ~x"./upgrade"l,
      level: ~x"level/text()"i,
      attack: ~x"attack/text()"Io,
      health: ~x"health/text()"Io,
      delay: ~x"cost/text()"Io,
      skills: skill,
    ]

    xml_string = File.read! filename

    data = xml_string |> xmap(
      units: [
        ~x"//unit"l,
        name: ~x"name/text()"s,
        id: ~x"id/text()"i,
        attack: ~x"attack/text()"Io,
        health: ~x"health/text()"Io,
        picture: ~x"picture/text()"s,
        delay: ~x"cost/text()"Io,
        type: ~x"type/text()"Io,
        rarity: ~x"rarity/text()"i,
        set: ~x"set/text()"i,
        subtypes: ~x"sub_type/text()"Il,
        skills: skill,
        upgrades: upgrade
      ],
      skill_types: [
        ~x"//skillType[not(id = 'displayEffect')]"l,
        id: ~x"id/text()"s,
        icon: ~x"icon/text()"s,
        order: ~x"order/text()"Io,
        name: ~x"name/text()"So,
        desc: ~x"desc/text()"So,
      ],
      card_sets: [
        ~x"//cardSet"l,
        id: ~x"id/text()"i,
        name: ~x"name/text()"s,
      ],
      unit_types: [
        ~x"//unitType"l,
        id: ~x"id/text()"i,
        name: ~x"name/text()"s,
      ]
    )
    %{ data |
      units: data.units |> map_by_id,
      card_sets: data.card_sets |> map_by_id,
      skill_types: data.skill_types |> map_by_id,
      unit_types: data.unit_types |> map_by_id
    }
  end

end
