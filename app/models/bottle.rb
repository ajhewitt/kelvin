class Bottle < Package
  # Bottles show their size on the board to set them apart from the usual cans:
  # "(660)" for millilitres, otherwise with the unit, as in "(12 oz)"
  def board_size
    amount, label = volume_parts
    return unless amount

    (label == "ml") ? "(#{amount})" : "(#{amount} #{label})"
  end
end
